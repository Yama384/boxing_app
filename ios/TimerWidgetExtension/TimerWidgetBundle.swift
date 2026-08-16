//
//  TimerWidgetBundle.swift
//  TimerWidgetExtension
//
//  Einstiegspunkt der Widget Extension -- bündelt alle Widgets, die diese
//  Extension bereitstellt (hier nur die Live Activity).
//

import WidgetKit
import SwiftUI

@main
struct TimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivityWidget()
    }
}
