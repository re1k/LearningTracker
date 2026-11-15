import Foundation
import SwiftUI
import UIKit
import SwiftData

//My data an be observed changes can be tracked update views that read them.
//also in here any var that toggles to true or false to show or hide, in here can  be managed!
@Observable
final class SetNewGoalViewModel { ///Observable object
    
    //Passed by the Parent View (Hosting screen)
    private let modelContext: ModelContext
    
    //Need to be publiseh to notfiy the view
    var target: Target

    init(target: Target, modelContext: ModelContext) {
            self.target = target
            self.modelContext = modelContext
        }

    func setTarget() {
        print("Goal:", target.goal)
        print("Duration:", target.duration)
        UpdatefreezeAmount(duration: target.duration)
        
        target.streakCounter = 0
        target.freezeCounter = 0
        
        modelContext.insert(target)

        do {
            try modelContext.save()
            
            //DEBUG
            print("Target saved",target.goal )
            print("Target freeze",target.freezeCounter)
            print("Target streak",target.streakCounter )
            print("Freeze allowance:", target.freezeAmount)
            let descriptor = FetchDescriptor<Target>()
            let savedTargets = try modelContext.fetch(descriptor)
            print("Targets in database:", savedTargets.count)
            
        } catch {
            print("Save failed:", error)
        }
    }
    

    private func UpdatefreezeAmount(duration: DurationOptions.RawValue){
        switch duration {
                case 7:
            target.freezeAmount = 2
                case 30:
            target.freezeAmount = 8
                case 365:
            target.freezeAmount = 96
                default:
            target.freezeAmount = 0
                }
    }
   
    func updateTarget() {

        print("Updating goal:", target.goal)
        print("New duration:", target.duration)

        // Recalculate freeze allowance
        UpdatefreezeAmount(duration: target.duration)

        // Reset progress
        target.streakCounter = 0
        target.freezeCounter = 0

        do {
            try modelContext.save()

            print("Target updated successfully!")
            print("Goal:", target.goal)
            print("Duration:", target.duration)
            print("Freeze allowance:", target.freezeAmount)

        } catch {
            print("Update failed:", error)
        }
    }
}


