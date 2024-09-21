//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {

    struct HomeFeature: Reducer {
        struct State: Equatable {
            var count = 0
            var fact: String?
            var isLoadingFact = false
            var isTimerOn = false
        }
        enum Action: Equatable {
            case decrementButtonTapped
            case factResponse(String)
            case getFactButtonTapped
            case incrementButtonTapped
            case timerTicked
            case toggleTimerButtonTapped
        }
        private enum CancelID {
            case timer
        }
//        @Dependency(\.continuousClock) var clock
//        @Dependency(\.numberFact) var numberFact
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .decrementButtonTapped:
                    state.count -= 1
                    state.fact = nil
                    return .none
                    
                case let .factResponse(fact):
                    state.fact = fact
                    state.isLoadingFact = false
                    return .none
                    
                case .getFactButtonTapped:
                    state.fact = nil
                    state.isLoadingFact = true
                    return .run { [count = state.count] send in
                        try await send(.factResponse(self.numberFact.fetch(count)))
                    }
                    
                case .incrementButtonTapped:
                    state.count += 1
                    state.fact = nil
                    return .none
                    
                case .timerTicked:
                    state.count += 1
                    return .none
                    
                case .toggleTimerButtonTapped:
                    state.isTimerOn.toggle()
                    if state.isTimerOn {
                        return .run { send in
                            for await _ in self.clock.timer(interval: .seconds(1)) {
                                await send(.timerTicked)
                            }
                        }
                        .cancellable(id: CancelID.timer)
                    } else {
                        return .cancel(id: CancelID.timer)
                    }
                }
            }
        }
    }

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Image(systemName: "music.mic.circle.fill")
                            .resizable()
                            .frame(width: 45, height: 45)
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                                .frame(width: 45, height: 45)
                            HStack {
                                Image(systemName: "bell.fill")
                                    .resizable()
                                    .frame(width: 21, height: 21)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                            .frame(width: 364, height: 64)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.black)
                                .padding(.leading, 15)
                            TextField("Search the podcast here...", text: .constant(""))
                                .padding(.leading, 5)
                        }
                        .frame(width: 364, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }
                    .padding()
                    Section(content: {
                        horizontalList(data: [1, 2, 3, 4, 5]) { _ in
                            ListViewHero()
                        }
                    }, header: {
                        HStack {
                            Text("Trending Podcasts")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    )
                    Section(content: {
                        LazyVStack(spacing: 10) {
                            ForEach(0..<6) { _ in
                                ListViewCell()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                    }, header: {
                        HStack {
                            Text("Trending Podcasts")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("See more..")
                                .foregroundStyle(Color(.blue))
                        }
                        .padding(.horizontal, 16)
                    }
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
//
//import ComposableArchitecture
//import SwiftUI
//
//struct NumberFactClient {
//  var fetch: @Sendable (Int) async throws -> String
//}
//extension NumberFactClient: DependencyKey {
//  static let liveValue = Self { number in
//    let (data, _) = try await URLSession.shared.data(
//      from: URL(string: "http://www.numbersapi.com/\(number)")!
//    )
//    return String(decoding: data, as: UTF8.self)
//  }
//}
//extension DependencyValues {
//  var numberFact: NumberFactClient {
//    get { self[NumberFactClient.self] }
//    set { self[NumberFactClient.self] = newValue }
//  }
//}
//
//struct CounterFeature: Reducer {
//  struct State: Equatable {
//    var count = 0
//    var fact: String?
//    var isLoadingFact = false
//    var isTimerOn = false
//  }
//  enum Action: Equatable {
//    case decrementButtonTapped
//    case factResponse(String)
//    case getFactButtonTapped
//    case incrementButtonTapped
//    case timerTicked
//    case toggleTimerButtonTapped
//  }
//  private enum CancelID {
//    case timer
//  }
//  @Dependency(\.continuousClock) var clock
//  @Dependency(\.numberFact) var numberFact
//  var body: some ReducerOf<Self> {
//    Reduce { state, action in
//      switch action {
//      case .decrementButtonTapped:
//        state.count -= 1
//        state.fact = nil
//        return .none
//
//      case let .factResponse(fact):
//        state.fact = fact
//        state.isLoadingFact = false
//        return .none
//
//      case .getFactButtonTapped:
//        state.fact = nil
//        state.isLoadingFact = true
//        return .run { [count = state.count] send in
//          try await send(.factResponse(self.numberFact.fetch(count)))
//        }
//
//      case .incrementButtonTapped:
//        state.count += 1
//        state.fact = nil
//        return .none
//
//      case .timerTicked:
//        state.count += 1
//        return .none
//
//      case .toggleTimerButtonTapped:
//        state.isTimerOn.toggle()
//        if state.isTimerOn {
//          return .run { send in
//            for await _ in self.clock.timer(interval: .seconds(1)) {
//              await send(.timerTicked)
//            }
//          }
//          .cancellable(id: CancelID.timer)
//        } else {
//          return .cancel(id: CancelID.timer)
//        }
//      }
//    }
//  }
//}
//
//struct ContentView: View {
//  let store: StoreOf<CounterFeature>
//
//  var body: some View {
//    WithViewStore(self.store, observe: { $0 }) { viewStore in
//      Form {
//        Section {
//          Text("\(viewStore.count)")
//          Button("Decrement") {
//            viewStore.send(.decrementButtonTapped)
//          }
//          Button("Increment") {
//            viewStore.send(.incrementButtonTapped)
//          }
//        }
//        Section {
//          Button {
//            viewStore.send(.getFactButtonTapped)
//          } label: {
//            HStack {
//              Text("Get fact")
//              if viewStore.isLoadingFact {
//                Spacer()
//                ProgressView()
//              }
//            }
//          }
//          if let fact = viewStore.fact {
//            Text(fact)
//          }
//        }
//        Section {
//          if viewStore.isTimerOn {
//            Button("Stop timer") {
//              viewStore.send(.toggleTimerButtonTapped)
//            }
//          } else {
//            Button("Start timer") {
//              viewStore.send(.toggleTimerButtonTapped)
//            }
//          }
//        }
//      }
//    }
//  }
//}
//
//#Preview {
//  ContentView(
//    store: Store(initialState: CounterFeature.State()) {
//      CounterFeature()
//        ._printChanges()
//    }
//  )
//}
