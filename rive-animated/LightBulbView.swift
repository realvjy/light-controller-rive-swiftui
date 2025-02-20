//
//  LightBulbView.swift
//  rive-animated
//
//  Created by vijay verma on 17/02/25.
//

import RiveRuntime
import SwiftUI

struct GradientSlider: View {
    @Binding var value: Float
    var range: ClosedRange<Float>
    var gradient: LinearGradient

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient Track
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradient)
                    .frame(height: 20)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 3)
                    .offset(
                        x: CGFloat(
                            (value - range.lowerBound)
                            / (range.upperBound - range.lowerBound))
                        * geometry.size.width - 12
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue =
                                Float(
                                    gesture.location.x / geometry.size.width
                                ) * (range.upperBound - range.lowerBound)
                                + range.lowerBound
                                value = min(
                                    max(newValue, range.lowerBound),
                                    range.upperBound)
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

struct OpacitySlider: View {
    @Binding var opacity: Float

    var body: some View {
        GradientSlider(
            value: $opacity,
            range: 0...0.7,
            gradient: LinearGradient(
                gradient: Gradient(colors: [Color.gray, Color.white]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onChange(of: opacity) { newValue in
            print("Opacity changed to: \(newValue)")  // Debug print
        }
    }
}

struct RadialGradientCircle: View {
    var opacity: Double
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.white, Color.black]),
                center: .center,
                startRadius: 10,
                endRadius: 60
            )
            .scaleEffect(x: 2.0, y: 1.8)
            .frame(width: 210, height: 180)
            .clipShape(Ellipse())
            .blur(radius: 12)
        }
        .blendMode(.plusLighter)
        .opacity(opacity)

    }
}

struct LightBulbView: View {
    @StateObject private var riveBulb = RiveViewModel(
        fileName: "riveBulb",
        stateMachineName: "Light Controller"
    )
    @State private var numberValue: Float = 0.0
    @State private var opacity: Float = 0.4
    @State private var debugLayout: Bool = true

    @State var shouldPresentSheet = false

    // Gradient colors
    let gradientColors: [Color] = [
        Color(hex: "#3503FF"),
        Color(hex: "#B609E8"),
        Color(hex: "#E8403B"),
        Color(hex: "#FFF50A"),
        Color(hex: "#6FFB06"),
    ]
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            let usableScreenHeight = screenHeight - (
                safeAreaTop + safeAreaBottom
            )
            //Main View
            ZStack{
                // Bulb
                ZStack {
                    ZStack {
                        // Rive animation view
                        ZStack {
                            riveBulb
                                .view()
                                .frame(width: 800, height: 800)
                                .clipped()  // Add clipping
                        }
                        .frame(
                            width: geometry.size.width, height: geometry.size.height
                        )
                        // Extra light adjust
                        ZStack {
                            Ellipse()
                                .fill(Color.white)
                                .frame(width: 80, height: 20)
                                .opacity(Double(opacity))
                                .blendMode(.plusLighter)
                                .blur(radius: 22)
                            RadialGradientCircle(opacity: Double(opacity))
                        }.offset(y: -50)

                    }
                }
                
                
                //Sliders
                
                //lighting Controller
                ZStack {
                    VStack{
                        ZStack {
                            ZStack {
                                Button(action: {
                                    shouldPresentSheet.toggle()
                                }) {
                                    VStack {
                                        Image("rive-light")
                                            .scaledToFit()
                                            .aspectRatio(contentMode: .fit)
                                                    
                                    }
                                }
                                .sheet(isPresented: $shouldPresentSheet) {
                                    AboutView()
                                }
                                
                            }.modifier(DebugLayoutModifier(debug: debugLayout))
                        }
                        Spacer()
                        // All slider
                        ZStack {
                            VStack {
                                ZStack {
                                    GradientSlider(
                                        value: $numberValue,
                                        range: 0...100,
                                        gradient: LinearGradient(
                                            gradient: Gradient(
                                                colors: gradientColors
                                            ),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .padding()
                                    .onChange(of: numberValue) { newValue, _ in
                                        riveBulb.setInput("ColorValue", value: newValue)
                                    }
                                }
                                
                                ZStack {
                                    OpacitySlider(opacity: $opacity)
                                        .padding()
                                    
                                }
                                ZStack{
                                    Circle().frame(width: 42)
                                }
                                
                            }
                        }
                        .padding(16)
                        .modifier(DebugLayoutModifier(debug: debugLayout))
                    }
                    .padding(.top, usableScreenHeight * 0.1)
                    .padding(.bottom, usableScreenHeight * 0.05)

                }
                
            }
            .frame(width: geometry.size.width, height: geometry.size.height)


        }
        .background(.clear)
        .ignoresSafeArea()

    }
}

struct AboutView: View {
    @State var shouldPresentSheet = false

    var body: some View {
        VStack {
            Circle()

        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    LightBulbView().preferredColorScheme(.dark)
}
