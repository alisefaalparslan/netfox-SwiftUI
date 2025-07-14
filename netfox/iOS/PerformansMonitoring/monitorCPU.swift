//
//  monitorCPU.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import Foundation

func getCPUUsage() -> Double? {
    var threadList: thread_act_array_t?
    var threadCount = mach_msg_type_number_t()

    let kerr = task_threads(mach_task_self_, &threadList, &threadCount)
    if kerr != KERN_SUCCESS {
        return nil
    }

    guard let threadList = threadList else {
        return nil
    }

    var totalUsageOfCPU: Double = 0

    for i in 0 ..< Int(threadCount) {
        var threadInfo = thread_basic_info()
        var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

        let kr = withUnsafeMutablePointer(to: &threadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                thread_info(threadList[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
            }
        }

        if kr != KERN_SUCCESS {
            return nil
        }

        let threadBasicInfo = threadInfo

        if (threadBasicInfo.flags & TH_FLAGS_IDLE) == 0 {
            // CPU usage is in percentage * 10 (e.g. 20 means 2%)
            totalUsageOfCPU += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
        }
    }

    // Deallocate the thread list
    let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
    vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), size)

    return totalUsageOfCPU
}
