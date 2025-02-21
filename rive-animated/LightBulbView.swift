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
    var gradientStops: [Gradient.Stop]
    @State private var thumbColor: Color
    
    // Add custom initializer
    init(value: Binding<Float>, range: ClosedRange<Float>, gradientStops: [Gradient.Stop]) {
        self._value = value
        self.range = range
        self.gradientStops = gradientStops
        
        // Calculate initial thumb color
        let initialPercentage = CGFloat((value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound))
        self._thumbColor = State(initialValue: gradientStops.interpolatedColor(at: initialPercentage))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient Track
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(gradient: Gradient(stops: gradientStops), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 36)

                // Thumb
                Circle()
                    .fill(thumbColor)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 3)
                    .offset(
                        x: max(8, min( // Add bounds to keep thumb within track
                            CGFloat(
                                (value - range.lowerBound)
                                / (range.upperBound - range.lowerBound)
                            ) * (geometry.size.width - 24), // Subtract thumb width
                            geometry.size.width - 32 // Maximum offset
                        ))
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
                                
                                // Calculate current color
                                let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                                thumbColor = gradientStops.interpolatedColor(at: percentage) // Update local thumbColor
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

struct OpacitySlider: View {
    @Binding var opacity: Float
    @State private var thumbColor: Color = .white // Add local state for thumb color
    
    var body: some View {
        GradientSlider(
            value: $opacity,
            range: 0...0.7,
            gradientStops: [
                Gradient.Stop(color: Color.white.opacity(0.4), location: 0),
                Gradient.Stop(color: Color.white, location: 1)
            ]
        )
        .onChange(of: opacity) { newValue in
            print("Opacity changed to: \(newValue)")
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
    @State private var isLightOn: Bool = true // Add this state variable

  
    
    @State var shouldPresentSheet = false
    @State private var currentColor: Color = .white

    // Gradient colors
    let gradientStops: [Gradient.Stop] = [
        Gradient.Stop(color: Color(hex: "#3503FF"), location: 0),
        Gradient.Stop(color: Color(hex: "#B609E8"), location: 0.25),
        Gradient.Stop(color: Color(hex: "#E8403B"), location: 0.5),
        Gradient.Stop(color: Color(hex: "#FFF50A"), location: 0.75),
        Gradient.Stop(color: Color(hex: "#6FFB06"), location: 1)
    ]
    var body: some View {
        ZStack {
            Color.black
                    .edgesIgnoringSafeArea(.all)
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
                                    .frame(width: 900, height: 900)
                                    .clipped()
                                
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
                            
                        }.offset(y: -20)
                    }
                    
                    
                    //Sliders
                    
                    //lighting Controller
                    ZStack {
                        VStack{
                            ZStack {
                                ZStack {
                                    Button(action: {
                                        shouldPresentSheet.toggle()
                                         // Haptic feedback on present
                                        let generator = UIImpactFeedbackGenerator(style: .soft)
                                        generator.impactOccurred()
                                    }) {
                                        VStack {
                                            Image("rive-light")
                                                .scaledToFit()
                                                .aspectRatio(contentMode: .fit)
                                            
                                        }
                                    }
                                    .sheet(isPresented: $shouldPresentSheet) {
                                        AboutView()
                                            .presentationDetents([ .large]) // Customize height
                                            .presentationBackground(.clear) // Ensure transparency
                                            .presentationDragIndicator(.visible)
                                            .presentationCornerRadius(30)
                                            .onDisappear {
                                                
                                            }
                                        
                                    }
                                    
                                }.modifier(DebugLayoutModifier(debug: debugLayout, mode: .outlineOnly))
                            }
                            Spacer()
                            // All slider
                            ZStack {
                                VStack {
                                    ZStack {
                                        GradientSlider(
                                            value: $numberValue,
                                            range: 10...60,
                                            gradientStops: gradientStops
                                            
                                        )
                                        .padding()
                                        .onChange(of: numberValue) { newValue, _ in
                                            riveBulb.setInput("ColorValue", value: newValue)
                                            
                                        }
                                    }
                                    
                                    ZStack {
                                        OpacitySlider(opacity: $opacity) // Add currentColor binding
                                            .padding()
                                        
                                    }
                                    ZStack {
                                        Button(action: {
                                            isLightOn.toggle() // Toggle the state
                                            if isLightOn {
                                                // Turn on: restore previous values
                                                riveBulb.setInput("ColorValue", value: numberValue)
                                                riveBulb.setInput("on", value: isLightOn)
                                            } else {
                                                // Turn off: reset color slider
//                                                numberValue = 0
                                                riveBulb.setInput("ColorValue", value: Float(0))
                                                riveBulb.setInput("on", value: isLightOn)
                                            }
                                        }) {
                                            Circle()
                                                .fill(currentColor.opacity(Double(opacity)))
                                                .frame(width: 42)
                                                .overlay(
                                                    Image(systemName: isLightOn ? "power" : "poweroff")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18, weight: .bold))
                                                )
                                        }
                                    }
                                    
                                }
                            }
                            .padding(16)
                            .modifier(DebugLayoutModifier(debug: debugLayout, mode: .outlineOnly))
                        }
                        .padding(.top, usableScreenHeight * 0.1)
                        .padding(.bottom, usableScreenHeight * 0.05)
                        
                    }
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                
            }.edgesIgnoringSafeArea(.all)
            
        }
        .background(Color.black)
        .preferredColorScheme(.dark)

    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hasTriggeredHaptic = false
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .background(.thinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack {
                Text("This is a blurred sheet")
                    .font(.title)
                    .padding()
            }
            .offset(y: offset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundClearView())
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation.height
                    if !hasTriggeredHaptic && offset > 0 {
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                        hasTriggeredHaptic = true
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                    hasTriggeredHaptic = false
                }
        )
    }
}

// Add this new view
struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}



#Preview {
    LightBulbView().preferredColorScheme(.dark)
}
