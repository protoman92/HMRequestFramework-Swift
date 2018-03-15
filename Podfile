# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def allPods
    pod 'HMEventSourceManager/Main', :git => 'https://github.com/Holmusk/HMEventSourceManager-iOS.git'
    pod 'SwiftUtilities/Main', git: 'https://github.com/protoman92/SwiftUtilities.git', :branch => 'legacy'
    pod 'Differentiator'
end

target 'HMRequestFramework' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    # Pods for HMRequestFramework
    allPods

    target 'HMRequestFrameworkTests' do
        inherit! :search_paths
        # Pods for testing
        allPods
        pod 'SwiftUtilitiesTests/Main', git: 'https://github.com/protoman92/SwiftUtilities.git', :branch => 'legacy'
    end
    
    target 'HMRequestFramework-Demo' do
        inherit! :search_paths
        # Pods for testing
        allPods
        pod 'RxDataSources'
        pod 'SwiftUtilitiesTests/Main', git: 'https://github.com/protoman92/SwiftUtilities.git', :branch => 'legacy'
    end
end
