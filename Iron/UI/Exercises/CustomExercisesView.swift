//
//  CustomExercisesView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import WorkoutDataKit

struct CustomExercisesView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var entitlementStore: EntitlementStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case createCustomExercise
        case buyPro
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .createCustomExercise:
            return CreateCustomExerciseSheet()
                .environmentObject(exerciseStore)
                .typeErased
        case .buyPro:
            return PurchaseSheet()
                .environmentObject(entitlementStore)
                .typeErased
        }
    }
    
    @State private var offsetsToDelete: IndexSet?
    
    private func deleteAtOffsets(offsets: IndexSet) {
        for i in offsets {
            assert(self.exerciseStore.customExercises[i].isCustom)
            let uuid = self.exerciseStore.customExercises[i].uuid
            self.deleteWorkoutExercises(with: uuid)
            self.exerciseStore.deleteCustomExercise(with: uuid)
        }
        self.managedObjectContext.saveOrCrash()
    }
    
    var body: some View {
        List {
            ForEach(exerciseStore.customExercises, id: \.id) { exercise in
                NavigationLink(exercise.title, destination: _ExerciseDetailView(exercise: exercise)
                    .environmentObject(self.settingsStore))
            }
            .onDelete { offsets in
                guard UIDevice.current.userInterfaceIdiom != .pad else { // TODO: actionSheet not supported on iPad yet (13.2)
                    self.deleteAtOffsets(offsets: offsets)
                    return
                }
                self.offsetsToDelete = offsets
            }
            Button(action: {
                self.activeSheet = self.entitlementStore.isPro ? .createCustomExercise : .buyPro
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Exercise")
                    if !entitlementStore.isPro {
                        Spacer()
                        Group {
                            Text("Iron Pro")
                            Image(systemName: "lock")
                        }.foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationBarItems(trailing: EditButton())
        .sheet(item: $activeSheet, content: { type in
            self.sheetView(type: type)
        })
        .actionSheet(item: $offsetsToDelete) { offsets in
            ActionSheet(title: Text("This cannot be undone."), message: Text("Warning: Any set belonging to this exercise will be deleted."), buttons: [
                .destructive(Text("Delete"), action: {
                    self.deleteAtOffsets(offsets: offsets)
                }),
                .cancel()
            ])
        }
    }
    
    private func deleteWorkoutExercises(with uuid: UUID) {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.exerciseUuid)) == %@", uuid as CVarArg)
        guard let workoutExercises = try? managedObjectContext.fetch(request) else { return }
        workoutExercises.forEach { managedObjectContext.delete($0) }
    }
}

#if DEBUG
struct CustomExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        CustomExercisesView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
