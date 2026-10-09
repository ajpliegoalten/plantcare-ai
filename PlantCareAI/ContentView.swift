import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PlantListViewModel

    var body: some View {
        PlantListView(viewModel: viewModel)
    }
}
