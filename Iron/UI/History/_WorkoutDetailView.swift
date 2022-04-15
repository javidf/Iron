//
//  WorkoutDetailView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit
import os.log

struct _WorkoutDetailView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var sceneState: SceneState
    @ObservedObject var workout: Workout

//    @Environment(\.editMode) var editMode
    @State private var showingExerciseSelectorSheet = false
    @State private var showingOptionsMenu = false
    
    @State private var activityItems: [Any]?

    @State private var workoutCommentInput: String? = nil
    private var workoutComment: Binding<String> {
        Binding(
            get: {
                self.workoutCommentInput ?? self.workout.comment ?? ""
            },
            set: { newValue in
                self.workoutCommentInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutCommentInput() {
        guard let newValue = workoutCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutCommentInput = newValue
        workout.comment = newValue.isEmpty ? nil : newValue
        self.managedObjectContext.saveOrCrash()
    }
    
    @State private var workoutTitleInput: String? = nil
    private var workoutTitle: Binding<String> {
        Binding(
            get: {
                self.workoutTitleInput ?? self.workout.title ?? ""
            },
            set: { newValue in
                self.workoutTitleInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutTitleInput() {
        guard let newValue = workoutTitleInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutTitleInput = newValue
        workout.title = newValue.isEmpty ? nil : newValue
    }

    private var workoutExercises: [WorkoutExercise] {
        workout.workoutExercises?.array as? [WorkoutExercise] ?? []
    }
    
    private func workoutSets(workoutExercise: WorkoutExercise) -> [WorkoutSet] {
        workoutExercise.workoutSets?.array as? [WorkoutSet] ?? []
    }
    
    private func workoutExerciseView(workoutExercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading) {
            Text(workoutExercise.exercise(in: self.exerciseStore.exercises)?.title ?? "")
                .font(.body)
            workoutExercise.comment.map {
                Text($0.enquoted)
                    .lineLimit(1)
                    .font(Font.caption.italic())
                    .foregroundColor(.secondary)
            }
            ForEach(self.workoutSets(workoutExercise: workoutExercise)) { workoutSet in
                Text(workoutSet.logTitle(weightUnit: self.settingsStore.weightUnit))
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                WorkoutDetailBannerView(workout: workout)
                    .padding([.top, .bottom])
                    .listRowBackground(workout.muscleGroupColor(in: self.exerciseStore.exercises))
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            
            // editMode still doesn't work in 13.1 beta2
//            if editMode?.wrappedValue == .active {
                Section {
                    // TODO: add clear button
                    TextField("Title", text: workoutTitle, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveWorkoutTitleInput()
                        }
                    })
                    TextField("Comment", text: workoutComment, onEditingChanged: { isEditingTextField in
                        if !isEditingTextField {
                            self.adjustAndSaveWorkoutCommentInput()
                        }
                    })
                }
                
                Section {
                    DatePicker(selection: $workout.safeStart, in: ...min(workout.safeEnd, Date())) {
                        Text("Start")
                    }
                    
                    DatePicker(selection: $workout.safeEnd, in: workout.safeStart...Date()) {
                        Text("End")
                    }
                }
//            }

            Section {
                ForEach(workoutExercises) { workoutExercise in
                    NavigationLink(destination: WorkoutExerciseDetailView(workoutExercise: workoutExercise).environmentObject(self.settingsStore)) {
                        self.workoutExerciseView(workoutExercise: workoutExercise)
                    }
                }
                .onDelete { offsets in
                    let workoutExercises = self.workoutExercises
                    for i in offsets {
                        let workoutExercise = workoutExercises[i]
                        self.managedObjectContext.delete(workoutExercise)
                        workoutExercise.workout?.removeFromWorkoutExercises(workoutExercise)
                    }
                    self.managedObjectContext.saveOrCrash()
                }
                .onMove { source, destination in
                    guard var workoutExercises = self.workout.workoutExercises?.array as? [WorkoutExercise] else { return }
                    workoutExercises.move(fromOffsets: source, toOffset: destination)
                    self.workout.workoutExercises = NSOrderedSet(array: workoutExercises)
                    self.managedObjectContext.saveOrCrash()
                }
                
                Button(action: {
                    self.showingExerciseSelectorSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercises")
                    }
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .navigationBarTitle(Text(workout.displayTitle(in: exerciseStore.exercises)), displayMode: .inline)
        .navigationBarItems(trailing:
            HStack(spacing: NAVIGATION_BAR_SPACING) {
                Button(action: {
                    self.showingOptionsMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .padding([.leading, .top, .bottom])
                }
                EditButton()
            }
        )
        .sheet(isPresented: $showingExerciseSelectorSheet) {
            AddExercisesSheet(
                exercises: self.exerciseStore.shownExercises,
                recentExercises: AddExercisesSheet.loadRecentExercises(context: self.managedObjectContext, exercises: self.exerciseStore.shownExercises),
                onAdd: { selection in
                    for exercise in selection {
                        let workoutExercise = WorkoutExercise.create(context: self.managedObjectContext)
                        self.workout.addToWorkoutExercises(workoutExercise)
                        workoutExercise.exerciseUuid = exercise.uuid
                    }
                    self.managedObjectContext.saveOrCrash()
            })
        }
        .actionSheet(isPresented: $showingOptionsMenu) {
            ActionSheet(title: Text("Workout"), buttons: [
                .default(Text("Share"), action: {
                    guard let logText = self.workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                    self.activityItems = [logText]
                }),
                .default(Text("Repeat"), action: {
                    Self.repeatWorkout(workout: self.workout, settingsStore: self.settingsStore, sceneState: sceneState)
                }),
                .default(Text("Repeat (Blank)"), action: {
                    Self.repeatWorkoutBlank(workout: self.workout, settingsStore: self.settingsStore, sceneState: sceneState)
                }),
                .cancel()
            ])
        }
        .overlay(ActivitySheet(activityItems: $activityItems))
    }
}

// MARK: Actions
extension _WorkoutDetailView {
    static func repeatWorkout(workout: Workout, settingsStore: SettingsStore, sceneState: SceneState) {
        guard let newWorkout = workout.copyForRepeat(blank: false) else { return }
        
        guard let context = workout.managedObjectContext else { return }
        guard let count = try? context.count(for: Workout.currentWorkoutFetchRequest), count == 0 else {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        newWorkout.startOrCrash()
        
        sceneState.selectedTab = .workout
    }
    
    static func repeatWorkoutBlank(workout: Workout, settingsStore: SettingsStore, sceneState: SceneState) {
        guard let newWorkout = workout.copyForRepeat(blank: true) else { return }
        
        guard let context = workout.managedObjectContext else { return }
        guard let count = try? context.count(for: Workout.currentWorkoutFetchRequest), count == 0 else {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        newWorkout.startOrCrash()
        
        sceneState.selectedTab = .workout
    }
}

struct _WorkoutDetailView_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            _WorkoutDetailView(workout: MockWorkoutData.metricRandom.workout)
                .mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
