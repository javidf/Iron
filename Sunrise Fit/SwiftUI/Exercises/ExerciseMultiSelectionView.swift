//
//  ExerciseMultiSelectionView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 20.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct ExerciseMultiSelectionView<Selection>: View where Selection: SelectionManager, Selection.SelectionValue == Exercise {
    var exerciseMuscleGroups: [[Exercise]]
    @Binding var selection: Selection
    
    var body: some View {
        VStack {
            List(selection: $selection) {
                ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exercises in
                    Section(header: Text(exercises.first?.muscleGroup.capitalized ?? "")) {
                        ForEach(exercises, id: \.self) { exercise in
                            Text(exercise.title)
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
        }
    }
}

#if DEBUG
struct ExerciseMultiSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseMultiSelectionView(exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped, selection: .constant(Set()))
    }
}
#endif
