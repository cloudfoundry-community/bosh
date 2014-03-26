namespace :local do
  desc 'build a Stemcell locally'
  task :build_with_local_os_image, [:infrastructure_name, :operating_system_name, :agent_name, :os_image_path] do |_, args|
    require 'bosh/dev/build'
    require 'bosh/dev/gem_components'
    require 'bosh/stemcell/build_environment'
    require 'bosh/stemcell/definition'
    require 'bosh/stemcell/stage_collection'
    require 'bosh/stemcell/stage_runner'
    require 'bosh/stemcell/stemcell_builder'

    # build stemcell
    build = Bosh::Dev::Build::Local.new(ENV['CANDIDATE_BUILD_NUMBER'], Bosh::Dev::LocalDownloadAdapter.new(Logger.new(STDERR)))
    gem_components = Bosh::Dev::GemComponents.new(build.number)
    definition = Bosh::Stemcell::Definition.for(args.infrastructure_name, args.operating_system_name, args.agent_name)
    environment = Bosh::Stemcell::BuildEnvironment.new(
      ENV.to_hash,
      definition,
      build.number,
      build.release_tarball_path,
      args.os_image_path,
    )
    collection = Bosh::Stemcell::StageCollection.new(definition)
    runner = Bosh::Stemcell::StageRunner.new(
      build_path: environment.build_path,
      command_env: environment.command_env,
      settings_file: environment.settings_path,
      work_path: environment.work_path,
    )

    builder = Bosh::Stemcell::StemcellBuilder.new(
      gem_components: gem_components,
      environment: environment,
      collection: collection,
      runner: runner,
    )
    builder.build

    sh(environment.stemcell_rspec_command)

    mkdir_p('tmp')
    cp(environment.stemcell_file, 'tmp')
  end
end
