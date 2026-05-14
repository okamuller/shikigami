import SwiftUI

struct OnboardingFlow: View {
    let deps: AppDependencies
    let onComplete: (AppUser) -> Void

    @State private var vm: OnboardingViewModel

    init(deps: AppDependencies, onComplete: @escaping (AppUser) -> Void) {
        self.deps = deps
        self.onComplete = onComplete
        _vm = State(initialValue: OnboardingViewModel(userRepo: deps.userRepo))
    }

    var body: some View {
        ZStack {
            StarfieldView()

            switch vm.currentStep {
            case .welcome:
                WelcomeStep { vm.advance() }
            case .birthDate:
                BirthDateStep(birthDate: $vm.birthDate) { vm.advance() }
            case .gender:
                GenderStep(gender: $vm.gender) { vm.advance() }
            case .topic:
                TopicStep(topic: $vm.topic) { vm.advance() }
            case .shikigamiReveal:
                ShikigamiRevealStep(
                    vm: vm,
                    onComplete: { user in onComplete(user) }
                )
            }
        }
        .animation(.easeInOut, value: vm.currentStep)
    }
}
