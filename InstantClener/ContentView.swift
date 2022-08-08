//
//  ContentView.swift
//  InstantClener
//
//  Created by user7007 on 08/08/2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView().environmentObject(Store())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
