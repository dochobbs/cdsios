import Combine
import Foundation
import Security

final class SecureSettings: ObservableObject {
    static let shared = SecureSettings()

    @Published private(set) var apiKey: String?
    @Published private(set) var model: ClaudeConfiguration.Model = .default

    private let keychainService = "com.dochobbs.clinicalapp"
    private let apiKeyKey = "anthropic_api_key"
    private let modelKey = "selected_model"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        apiKey = readKeychainValue(for: apiKeyKey)
        if let storedModel = UserDefaults.standard.string(forKey: modelKey),
           let model = ClaudeConfiguration.Model(rawValue: storedModel) {
            self.model = model
        }
    }

    func update(apiKey: String, model: ClaudeConfiguration.Model) throws {
        try storeKeychainValue(apiKey, for: apiKeyKey)
        UserDefaults.standard.set(model.rawValue, forKey: modelKey)

        Task { @MainActor in
            self.apiKey = apiKey
            self.model = model
        }
    }

    func configuration() -> ClaudeConfiguration {
        ClaudeConfiguration(apiKey: apiKey, model: model)
    }

    private func storeKeychainValue(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]

        let updateQuery: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
            }
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    private func readKeychainValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
