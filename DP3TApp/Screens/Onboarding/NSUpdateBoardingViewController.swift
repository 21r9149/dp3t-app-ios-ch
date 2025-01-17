//
/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import Foundation

class NSUpdateBoardingViewController: NSOnboardingBaseViewController {
    private let germanyUpdateViewController = NSUpdateBoardingGermanyViewController()

    override internal var stepViewControllers: [NSOnboardingContentViewController] {
        [germanyUpdateViewController]
    }

    override internal var finalStepIndex: Int {
        return stepViewControllers.firstIndex(of: germanyUpdateViewController)!
    }

    override internal func completedOnboarding() {
        UserStorage.shared.hasCompletedUpdateBoardingGermany = true
    }
}
