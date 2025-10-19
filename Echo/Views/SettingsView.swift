//
//  SettingsView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiAddress = "http://localhost:1234"
    @State private var apiKey = "exampleapikey123"
    @State private var modelName = "qwen/qwen3-4b-2507"
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Main Content
            mainContentView

            Spacer()

            // Save Button
            saveButton
        }
        .background(Color(red: 0.102, green: 0.114, blue: 0.180)) // #1a1d2e
        .ignoresSafeArea()
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                // 返回按钮
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Text("设置")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .tracking(-0.3125)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(height: 72)
    }

    private var mainContentView: some View {
        VStack(spacing: 24) {
            // API Address 输入
            SettingsInputField(
                label: "API Address",
                text: $apiAddress,
                placeholder: "http://localhost:1234"
            )

            // API Key 输入
            SettingsInputField(
                label: "API Key",
                text: $apiKey,
                placeholder: "exampleapikey123",
                isSecure: true
            )

            // Model Name 输入
            SettingsInputField(
                label: "Model Name",
                text: $modelName,
                placeholder: "qwen/qwen3-4b-2507"
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var saveButton: some View {
        Button(action: {
            saveSettings()
        }) {
            Text("Save")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .tracking(-0.3125)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.42, green: 0.48, blue: 0.92)) // #6b7bea
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 80)
    }

    private func saveSettings() {
        // 验证输入
        guard !apiAddress.isEmpty else {
            alertMessage = "API地址不能为空"
            showingAlert = true
            return
        }

        guard !apiKey.isEmpty else {
            alertMessage = "API密钥不能为空"
            showingAlert = true
            return
        }

        guard !modelName.isEmpty else {
            alertMessage = "模型名称不能为空"
            showingAlert = true
            return
        }

        // 验证API地址格式
        guard apiAddress.hasPrefix("http://") || apiAddress.hasPrefix("https://") else {
            alertMessage = "API地址格式不正确，需要以http://或https://开头"
            showingAlert = true
            return
        }

        // 保存设置到UserDefaults
        UserDefaults.standard.set(apiAddress, forKey: "api_address")
        UserDefaults.standard.set(apiKey, forKey: "api_key")
        UserDefaults.standard.set(modelName, forKey: "model_name")

        alertMessage = "设置已保存"
        showingAlert = true
    }

    private func loadSettings() {
        // 从UserDefaults加载设置
        if let savedAddress = UserDefaults.standard.string(forKey: "api_address") {
            apiAddress = savedAddress
        }
        if let savedKey = UserDefaults.standard.string(forKey: "api_key") {
            apiKey = savedKey
        }
        if let savedModel = UserDefaults.standard.string(forKey: "model_name") {
            modelName = savedModel
        }
    }
}

struct SettingsInputField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tracking(-0.3125)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                    .tracking(-0.3125)
                    .padding(16)
                    .background(Color(red: 0.145, green: 0.157, blue: 0.224)) // #252839
                    .cornerRadius(14)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.69))
                    .tracking(-0.3125)
                    .padding(16)
                    .background(Color(red: 0.145, green: 0.157, blue: 0.224)) // #252839
                    .cornerRadius(14)
            }
        }
    }
}

#Preview {
    SettingsView()
}