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

import CrowdNotifierSDK
import Foundation

extension VenueInfo {
    var locationData: SwissCovidLocationData? {
        return try? SwissCovidLocationData(serializedData: countryData)
    }

    var venueType: SwissCovidLocationData.VenueType? {
        return locationData?.type
    }

    static func defaultImage(large: Bool) -> UIImage {
        return UIImage(named: large ? "illus-other" : "illus-other-small")!
    }

    var subtitle: String? {
        let elements: [String] = [address, locationData?.room ?? ""].compactMap { $0.isEmpty ? nil : $0 }
        if elements.isEmpty {
            return nil
        }
        return elements.joined(separator: ", ")
    }
}
