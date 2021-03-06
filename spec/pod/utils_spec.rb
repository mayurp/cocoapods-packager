require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Package do
    after do
      Dir.glob("Pods").each { |dir| Pathname.new(dir).rmtree }
    end

    it "uses additional spec repos passed on the command line" do
      SourcesManager.stubs(:search).returns(nil)
      nil::NilClass.any_instance.stubs(:install!)
      Installer.expects(:new).with {
        |sandbox, podfile| podfile.sources == ['foo', 'bar']
      }

      command = Command.parse(%w{ package spec/fixtures/KFData.podspec --spec-sources=foo,bar})
      command.send(:install_pod, :osx, nil)

    end

    it "uses only the master repo if no spec repos were passed" do
      SourcesManager.stubs(:search).returns(nil)
      nil::NilClass.any_instance.stubs(:install!)
      Installer.expects(:new).with {
          |sandbox, podfile| podfile.sources == ['https://github.com/CocoaPods/Specs.git']
        }

      command = Command.parse(%w{ package spec/fixtures/KFData.podspec })
      command.send(:install_pod, :osx, nil)
    end

    it "creates seperate static and dynamic target if dynamic is passed" do
      source_dir = Dir.pwd

      SourcesManager.stubs(:search).returns(nil)

      command = Command.parse(%w{ package spec/fixtures/NikeKit.podspec -dynamic})
      command. create_working_directory

      command.config.sandbox_root       = 'Pods'
      command.config.integrate_targets  = false

      static_sandbox = command.build_static_sandbox(true)
      static_installer = command.install_pod(:ios, static_sandbox)

      dynamic_sandbox = command.build_dynamic_sandbox(static_sandbox, static_installer)
      command.install_dynamic_pod(dynamic_sandbox, static_sandbox, static_installer)

      static_sandbox_dir = Dir.new(Dir.pwd << "/Pods/Static")
      dynamic_sandbox_dir = Dir.new(Dir.pwd << "/Pods/Dynamic")

      static_sandbox_dir.to_s.should.not.be.empty
      dynamic_sandbox_dir.to_s.should.not.be.empty

      Dir.chdir(source_dir)
    end
  end
end
