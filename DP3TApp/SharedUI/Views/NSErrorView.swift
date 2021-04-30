/*
 * Copyright (c) 2020 Ubique Innovation AG <https://www.ubique.ch>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * SPDX-License-Identifier: MPL-2.0
 */

import UIKit

class NSErrorView: UIView {
    // MARK: - Views

    private let stackView = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = NSLabel(.uppercaseBold, textColor: .ns_red, numberOfLines: 0, textAlignment: .center)
    private let textLabel = NSLabel(.textLight, textColor: .ns_text, textAlignment: .center)
    private let errorCodeLabel = NSLabel(.smallRegular, textAlignment: .center)
    private let actionButton = NSUnderlinedButton()
    private let activityIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .white)
        }
    }()

    // MARK: - Model

    struct NSErrorViewModel {
        var icon: UIImage
        var title: String
        var text: String
        var buttonTitle: String?
        var errorCode: String?
        var action: ((NSErrorView?) -> Void)?
        var customColor: UIColor? = nil
    }

    var model: NSErrorViewModel? {
        didSet { update() }
    }

    init(model: NSErrorViewModel) {
        self.model = model

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        setupView()
        setupAccessibility()

        update()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .ns_backgroundSecondary
        layer.cornerRadius = 5

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = NSPadding.medium
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: NSPadding.medium + NSPadding.small, left: 2 * NSPadding.medium, bottom: NSPadding.medium, right: 2 * NSPadding.medium)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func update() {
        imageView.image = model?.icon
        titleLabel.text = model?.title
        titleLabel.accessibilityLabel = "\("loading_view_error_title".ub_localized): \(titleLabel.text ?? "")"
        textLabel.text = model?.text
        actionButton.touchUpCallback = { [weak self] in
            self?.model?.action?(self)
        }
        actionButton.title = model?.buttonTitle

        stackView.setNeedsLayout()
        stackView.clearSubviews()

        stackView.addArrangedView(imageView)
        stackView.addArrangedView(titleLabel)
        stackView.addArrangedView(textLabel)
        if model?.action != nil {
            stackView.addArrangedView(actionButton)
            stackView.addArrangedView(activityIndicator)
            activityIndicator.hidesWhenStopped = true
            activityIndicator.stopAnimating()
        }
        if let code = model?.errorCode {
            stackView.addArrangedView(errorCodeLabel)
            errorCodeLabel.text = code
        }
        stackView.addSpacerView(20)

        if let color = model?.customColor {
            imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = color
            titleLabel.textColor = color
        }

        stackView.layoutIfNeeded()

        updateAccessibility()
    }

    public var isEnabled: Bool {
        get {
            actionButton.isEnabled
        }
        set {
            actionButton.isEnabled = newValue
        }
    }

    public func startAnimating() {
        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.startAnimating()
        }
    }

    public func stopAnimating() {
        UIView.animate(withDuration: 0.2) {
            self.activityIndicator.stopAnimating()
        }
    }

    // MARK: - Factory

    static func tracingErrorView(for state: UIStateModel.TracingState, isHomeScreen: Bool) -> NSErrorView? {
        if let model = self.model(for: state, isHomeScreen: isHomeScreen) {
            return NSErrorView(model: model)
        }

        return nil
    }

    static var tracingDisabledInfoView: NSErrorView {
        let model = NSErrorViewModel(icon: UIImage(named: "ic-info")!,
                                            title: "tracing_turned_off_title".ub_localized,
                                            text: "tracing_turned_off_text".ub_localized,
                                            buttonTitle: "activate_tracing_button".ub_localized,
                                            action: { _ in
                                                TracingManager.shared.startTracing()
                                            })
        return NSErrorView(model: model)
    }

    static func model(for state: UIStateModel.TracingState, isHomeScreen: Bool) -> NSErrorViewModel? {
        switch state {
        case .tracingDisabled:
            let icon: UIImage
            let customColor: UIColor?
            if UserStorage.shared.hasStoppedTracingOnce {
                icon = UIImage(named: "ic-info")!
                customColor = .ns_text
            } else {
                icon = UIImage(named: "ic-error")!
                customColor = nil
            }

            if isHomeScreen {
                return NSErrorViewModel(icon: icon,
                                               title: "tracing_turned_off_title".ub_localized,
                                               text: "tracing_turned_off_text".ub_localized,
                                               buttonTitle: "activate_tracing_button".ub_localized,
                                               action: { _ in
                                                   TracingManager.shared.startTracing()
                                               },
                                               customColor: customColor)
            } else {
                return NSErrorViewModel(icon: icon,
                                               title: "tracing_turned_off_title".ub_localized,
                                               text: "tracing_turned_off_detailed_text".ub_localized,
                                               buttonTitle: nil,
                                               action: nil,
                                               customColor: customColor)
            }
        case let .tracingPermissionError(code):
            let icon = UIImage(named: "ic-en-error")!
            let title = "tracing_permission_error_title_ios".ub_localized.replaceSettingsString
            let text = "tracing_permission_error_text_ios".ub_localized.replaceSettingsString
            if #available(iOS 13.7, *) {
                return NSErrorViewModel(icon: icon,
                                               title: title,
                                               text: text,
                                               buttonTitle: "ios_tracing_permission_error_button".ub_localized,
                                               errorCode: code,
                                               action: { _ in
                                                   guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                                                   NSSettingsTutorialViewController().presentInNavigationController(from: appDelegate.tabBarController, useLine: false)
                                               })
            } else {
                return NSErrorViewModel(icon: icon,
                                               title: title,
                                               text: text,
                                               buttonTitle: "onboarding_gaen_button_activate".ub_localized,
                                               errorCode: code,
                                               action: { _ in
                                                   guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                                                         UIApplication.shared.canOpenURL(settingsUrl) else { return }
                                                   UIApplication.shared.open(settingsUrl)
                                               })
            }

        case .tracingAuthorizationUnknown:
            return NSErrorViewModel(icon: UIImage(named: "ic-en-error")!,
                                           title: "tracing_permission_error_title_ios".ub_localized.replaceSettingsString,
                                           text: "tracing_permission_error_text_ios".ub_localized.replaceSettingsString,
                                           buttonTitle: "onboarding_gaen_button_activate".ub_localized,
                                           action: { _ in
                                               TracingManager.shared.startTracing()
                                           })
        case .bluetoothTurnedOff:
            return NSErrorViewModel(icon: UIImage(named: "ic-bluetooth-off")!,
                                           title: "bluetooth_turned_off_title".ub_localized,
                                           text: "bluetooth_turned_off_text".ub_localized,
                                           buttonTitle: nil,
                                           action: nil)
        case .timeInconsistencyError:
            return NSErrorViewModel(icon: UIImage(named: "ic-error")!,
                                           title: "time_inconsistency_title".ub_localized,
                                           text: "time_inconsistency_text".ub_localized,
                                           buttonTitle: nil,
                                           action: nil)
        case .unexpectedError:
            return NSErrorViewModel(icon: UIImage(named: "ic-error")!,
                                           title: "begegnungen_restart_error_title".ub_localized,
                                           text: "begegnungen_restart_error_text".ub_localized,
                                           buttonTitle: nil,
                                           action: nil)
        default:
            return nil
        }
    }
}

// MARK: - Accessibility

extension NSErrorView {
    func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElementsHidden = false
        stackView.isAccessibilityElement = true
        updateAccessibility()
    }

    func updateAccessibility() {
        accessibilityElements = model?.action != nil ? [stackView, actionButton] : [stackView]
        stackView.accessibilityLabel = model.map { "\($0.title), \($0.text)" }
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}