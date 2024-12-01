//
//  SettingsFeatureTests.swift
//  AppTests
//
//  Created by Raidan on 2024. 12. 01..
//

import ComposableArchitecture
import Foundation
import Testing

@testable import podcast_ios

@MainActor
struct SettingsFeatureTests {
    @Test
    func test_initialState() async throws {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }
        #expect(store.state.isLoading == false)
    }
    
    @Test
    func test_clearCahceTest() async throws {
        let store = TestStore(initialState: SettingFeature.State()) {
            SettingFeature()
        }
        
        store.exhaustivity = .off
        
        let memoryUsageBeforeLoading = getMemoryUsage()
        
        let exploreStore = TestStore(initialState: ExploreFeature.State()) {
            ExploreFeature()
        }
        
        exploreStore.exhaustivity = .off
        
        let firstCategory = exploreStore.state.catagoryList.first!
        #expect(firstCategory.id == .arts)
        await exploreStore.send(.catagoryTapped(firstCategory))
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let memoryUsageAfterLoading = getMemoryUsage()
        
        if let beforeLoading = memoryUsageBeforeLoading, let afterLoading = memoryUsageAfterLoading {
            #expect(beforeLoading < afterLoading)
            await store.send(.confirmationDialog(.presented(.removeCacheButtonTapped)))
            if let memoryAfterCleaning = getMemoryUsage() {
                try await Task.sleep(nanoseconds: 100_000_000)
                #expect(memoryAfterCleaning < afterLoading)
            }
        }
    }
}


extension SettingsFeatureTests {
    func getMemoryUsage() -> Double? {
        var taskInfo = mach_task_basic_info()
        let size = MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(size)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: size) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMegabytes = Double(taskInfo.resident_size) / 1024.0 / 1024.0
            return usedMegabytes
        } else {
            return nil
        }
    }
}
