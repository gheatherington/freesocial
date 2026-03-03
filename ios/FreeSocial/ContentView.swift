import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            Text("FreeSocial")
                .font(.largeTitle)
                .fontWeight(.thin)
                .foregroundColor(.primary)
        }
    }
}
