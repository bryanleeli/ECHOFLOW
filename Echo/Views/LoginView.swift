//
//  LoginView.swift
//  Echo
//
//  Created by 李毅 on 10/19/25.
//

import SwiftUI

struct LoginView: View {
    @State private var nickname: String = ""
    @State private var isLoggedIn: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Logo 和标题区域
                VStack(spacing: 24) {
                    // EchoFlow Icon
                    AsyncImage(url: URL(string: "http://localhost:3845/assets/c9578b99ffb58b4fafc552dbfe8898947842df83.png")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 112, height: 112)
                    }
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.25), radius: 25, x: 0, y: 12.5)

                    // EchoFlow 标题
                    Text("EchoFlow")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .tracking(-0.3125)
                }
                .padding(.bottom, 182)

                Spacer()

                // 输入区域
                VStack(spacing: 16) {
                    // 昵称输入框
                    HStack {
                        TextField("输入你的昵称", text: $nickname)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 17)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(
                                color: .black.opacity(0.1),
                                radius: 25,
                                x: 0,
                                y: 12.5
                            )
                    )

                    // 登录按钮
                    Button(action: {
                        // 登录逻辑
                        if !nickname.isEmpty {
                            isLoggedIn = true
                        }
                    }) {
                        Text("登录")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(
                                        color: .black.opacity(0.1),
                                        radius: 25,
                                        x: 0,
                                        y: 12.5
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(nickname.isEmpty)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 80)
            }
            .background(
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 1.0),  // 蓝色
                        Color(red: 0.5, green: 0.3, blue: 0.9)   // 紫色
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            MainTabView()
        }
    }
}

#Preview {
    LoginView()
}