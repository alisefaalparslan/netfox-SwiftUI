//
//  monitorMemory.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

@preconcurrency import Darwin

var machTaskSelf: mach_port_t {
    mach_task_self_
}

func getMemoryUsage() -> Double? {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: info)) / 4

    let kerr = withUnsafeMutablePointer(to: &info) { infoPtr in
        infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            task_info(machTaskSelf,
                      task_flavor_t(TASK_VM_INFO),
                      intPtr,
                      &count)
        }
    }

    if kerr == KERN_SUCCESS {
        // physical footprint in bytes — close to Xcode memory report
        let physicalFootprint = Double(info.phys_footprint) / 1_048_576
        return physicalFootprint
    }

    return nil
}
