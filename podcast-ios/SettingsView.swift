//
//  SettingsView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SettingFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var alert: AlertState<Action.Alert>?
    @Presents var confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>?
      var isLoading = false
  }

  enum Action {
    case alert(PresentationAction<Alert>)
    case alertButtonTapped
    case confirmationDialog(PresentationAction<ConfirmationDialog>)
    case confirmationDialogButtonTapped

    @CasePathable
    enum Alert {
      case cacheRemovedComfirmedTapped
    }
    @CasePathable
    enum ConfirmationDialog {
      case removeCacheButtonTapped
    }
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .alert(.presented(.cacheRemovedComfirmedTapped)):
          state.isLoading = false
        state.alert = AlertState { TextState("All stored files have been removed!") }
        return .none

      case .alert:
        return .none

      case .alertButtonTapped:
        state.alert = AlertState {
          TextState("Alert!")
        } actions: {
          ButtonState(role: .cancel) {
            TextState("OK")
          }
        } message: {
          TextState("This is an alert")
        }
        return .none

      case .confirmationDialog(.presented(.removeCacheButtonTapped)):
          state.isLoading = true
          return .run { @MainActor send in
            let feedback =  clearAllAppCache()
              if feedback {
                  send(.alert(.presented(.cacheRemovedComfirmedTapped)))
              }
          }

      case .confirmationDialog:
        return .none

      case .confirmationDialogButtonTapped:
        state.confirmationDialog = ConfirmationDialogState {
          TextState("Confirmation dialog")
        } actions: {
          ButtonState(role: .cancel) {
            TextState("Cancel")
          }
            ButtonState(action: .removeCacheButtonTapped) {
            TextState("Remove all files")
          }
        } message: {
          TextState("This is a confirmation dialog.")
        }
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
    .ifLet(\.$confirmationDialog, action: \.confirmationDialog)
  }
}

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingFeature>
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SettingsViewContent(store: store)
                    .blur(
                        radius: store.isLoading ? 5 : 0
                    )
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Settings")
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .confirmationDialog($store.scope(state: \.confirmationDialog, action: \.confirmationDialog))
    }
}

struct SettingsViewContent: View {
    @Bindable var store: StoreOf<SettingFeature>
    var body: some View {
        List {
            Text("Remove all data")
                .onTapGesture {
                    store.send(.confirmationDialogButtonTapped)
                }
        }
    }
}
