//
//  GCDBlackBox.swift
//  VirtualTouristApp
//
//  Created by Sean Perez on 9/8/16.
//  Copyright © 2016 SeanPerez. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
