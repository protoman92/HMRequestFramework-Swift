Pod::Spec.new do |s|
    s.platform = :ios
    s.ios.deployment_target = '9.0'
    s.name = "HMRequestFramework"
    s.summary = "Network/Database request framework for iOS clients."
    s.requires_arc = true
    s.version = "1.0.1"
    s.license = { :type => "Apache-2.0", :file => "LICENSE" }
    s.author = { "Holmusk" => "viethai.pham@holmusk.com" }
    s.homepage = "https://github.com/Holmusk/HMRequestFramework-iOS.git"
    s.source = { :git => "https://github.com/Holmusk/HMRequestFramework-iOS.git", :tag => "#{s.version}"}
    s.dependency 'HMEventSourceManager/Main'
    s.dependency 'SwiftUtilities/Main'
    s.dependency 'RxDataSources'

    s.subspec 'Main' do |main|
    main.source_files = "HMRequestFramework/**/*.{swift}"
    end
end
