# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def allPods
    pod 'HMEventSourceManager/Main', :git => 'https://github.com/Holmusk/HMEventSourceManager-iOS.git'
    pod 'SwiftUtilities/Main', git: 'https://github.com/protoman92/SwiftUtilities.git'
    pod 'Differentiator'
end

def allDemoPods
    allPods
    pod 'MRProgress'
    pod 'RxDataSources'
    pod 'HMReactiveRedux/Main', :git => 'https://github.com/Holmusk/HMReactiveRedux-iOS.git'
    pod 'SwiftUIUtilities/Main', git: 'https://github.com/protoman92/SwiftUIUtilities.git'
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
        pod 'SwiftUtilitiesTests/Main'
    end
    
    target 'HMRequestFramework-Demo' do
        inherit! :search_paths
        # Pods for demo
        allDemoPods
    end
    
    target 'HMRequestFramework-FullDemo' do
        inherit! :search_paths
        # Pods for full demo
        allDemoPods
    end
    
    target 'HMRequestFramework-FullDemoTests' do
        inherit! :search_paths
        # Pods for full demo tests
        allDemoPods
        pod 'SwiftUtilitiesTests/Main'
    end
end
