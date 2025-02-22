//
//  LightBulbView.swift
//  rive-animated
//
//  Created by vijay verma on 17/02/25.
//

import RiveRuntime
import SwiftUI

struct GradientSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var gradientStops: [Gradient.Stop]
    @State private var thumbColor: Color
    @State private var previousValue: Double
    @Binding var currentColor: Color 

    init(
        value: Binding<Double>,
        currentColor: Binding<Color>,
        range: ClosedRange<Double>,
        gradientStops: [Gradient.Stop]
    ) {
        self._value = value
        self.range = range
        self.gradientStops = gradientStops
        self._previousValue = State(initialValue: value.wrappedValue)

        let initialPercentage = CGFloat(
            (value.wrappedValue - range.lowerBound) / (
                range.upperBound - range.lowerBound
            )
        )
        self._thumbColor = State(
            initialValue: gradientStops.interpolatedColor(at: initialPercentage)
        )
        let initialColor = gradientStops.interpolatedColor(
            at: initialPercentage
        )
        self._thumbColor = State(initialValue: initialColor)
        self._currentColor = currentColor // Initialize currentColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Behind track (2px smaller on all sides)
                RoundedRectangle(
                    cornerRadius: 26
                ) // Slightly larger corner radius
                .fill(Color(hex: "#15171E"))
                .frame(
                    height: geometry.size.height + 4
                ) //  4px (2px top and bottom)
                .padding(
                    .horizontal,
                    -2
                ) // Remove 2px padding on left and right
                .shadow(
                    color: .white.opacity(0.2),
                    radius: 0.2,
                    x: 0,
                    y: 0.5
                ) // Outer shadow
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(1), lineWidth: 1)
                        .offset(x: 0, y: 0.5)
                        .mask(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [.black, .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .blur(radius: 1)
                ) // Inner shadow

                //main track
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: gradientStops),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        height: geometry.size.height - 4
                    ) // Subtract 4px (2px top and bottom)
                    .padding(.horizontal, 2)

                // Thumb
                Circle()
                    .fill(thumbColor)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 2)
                    .offset(
                        x: max(6, min(
                            CGFloat(
                                (value - range.lowerBound)
                                / (range.upperBound - range.lowerBound)
                            ) * (geometry.size.width - 32),
                            geometry.size.width - 42
                        ))
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue =
                                Double(
                                    gesture.location.x / geometry.size.width
                                ) * (range.upperBound - range.lowerBound)
                                + range.lowerBound
                                value = min(
                                    max(newValue, range.lowerBound),
                                    range.upperBound)



                                // Add debug log for value change
                                print(
                                    "GradientSlider value changed: \(value) (range: \(range.lowerBound) to \(range.upperBound))"
                                )
                                let percentage = CGFloat(
                                    (value - range.lowerBound) / (
                                        range.upperBound - range.lowerBound
                                    )
                                )
                                thumbColor = gradientStops
                                    .interpolatedColor(at: percentage)
                                currentColor = thumbColor 
                                
                                // Add subtle haptic feedback
                                if abs(newValue - previousValue) > (range.upperBound - range.lowerBound) * 0.1 {
                                    let generator = UIImpactFeedbackGenerator(
                                        style: .soft
                                    )
                                    generator.prepare()
                                    generator.impactOccurred(intensity: 0.4)
                                    previousValue = newValue 
                                }
                            }
                    )
            }
        }
        .frame(height: 48) // Set overall container height
        
    }
}

struct OpacitySlider: View {
    @Binding var opacity: Double
    @Binding var currentColor: Color // Add binding for current color
    @State private var thumbColor: Color = .white
    var isLightOn: Bool
    
    init(
        opacity: Binding<Double>,
        currentColor: Binding<Color>,
        isLightOn: Bool
    ) {
        self._opacity = opacity
        self._currentColor = currentColor
        self.isLightOn = isLightOn
    }
    
    var body: some View {
        GradientSlider(
            value: $opacity,
            currentColor: $currentColor, // Pass the binding
            range: 0...0.7,
            gradientStops: [
                Gradient.Stop(color: Color.white.opacity(0.2), location: 0),
                Gradient.Stop(color: Color.white.opacity(1), location: 1)
            ]
        )
        .onChange(of: opacity) { newValue in
            // Update both thumb color and current color
            thumbColor = Color.white.opacity(newValue)
            currentColor = thumbColor
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
        .animation(.easeInOut(duration: 0.2).delay(0.2), value: opacity)
    }
}

struct LightBulbView: View {
    @StateObject private var riveBulb = RiveViewModel(
        fileName: "riveBulb",
        stateMachineName: "Light Controller"
    )
    @State private var numberValue: Double = 10.0
    @State private var opacity: Double = 0.2
    @State private var debugLayout: Bool = false // true to check line and fill
    @State private var isLightOn: Bool = false
  
    
    @State var shouldPresentSheet = false
    @State private var currentColor: Color = Color(hex: "#3503FF")
    @State private var currentOpacityColor: Color = .white

    // Gradient colors
    let gradientStops: [Gradient.Stop] = [
        Gradient.Stop(color: Color(hex: "#3503FF"), location: 0),
        Gradient.Stop(color: Color(hex: "#B609E8"), location: 0.25),
        Gradient.Stop(color: Color(hex: "#E8403B"), location: 0.45),
        Gradient.Stop(color: Color(hex: "#FD5917"), location: 0.5),
        Gradient.Stop(color: Color(hex: "#FFF50A"), location: 0.75),
        Gradient.Stop(color: Color(hex: "#CCFF24"), location: 0.8),
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
                                riveBulb.view()
                                    .frame(width: 900, height: 900)
                                    .clipped()
                                    .modifier(
                                        DebugLayoutModifier(
                                            debug: debugLayout,
                                            mode: .outlineOnly
                                        )
                                    )
                            }
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .modifier(
                                DebugLayoutModifier(
                                    debug: debugLayout,
                                    mode: .outlineOnly
                                )
                            )
                            
                            // Extra light adjust
                            ZStack {
                                Ellipse()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 20)
                                    .opacity(
                                        isLightOn ? Double(opacity) : 0
                                    ) // Add isLightOn check
                                    .blendMode(.plusLighter)
                                    .blur(radius: 22)
                                RadialGradientCircle(
                                    opacity: isLightOn ? opacity : 0
                                ) // Add isLightOn check
                            }.offset(y: -50)
                        }.offset(y: -40)
                    }
                    
                    
                    //Sliders
                    
                    //lighting Controller
                    ZStack {
                        VStack{
                            
                            ZStack {
                                ZStack {
                                    Button(
                                        action: {
                                            shouldPresentSheet.toggle()
                                            // Haptic feedback on present
                                            let generator = UIImpactFeedbackGenerator(
                                                style: .soft
                                            )
                                            generator.impactOccurred()
                                        }) {
                                            VStack {
                                                Image("rive-light")
                                                    .scaledToFit()
                                                    .aspectRatio(
                                                        contentMode: .fit
                                                    )
                                            
                                            }.modifier(
                                                DebugLayoutModifier(
                                                    debug: debugLayout,
                                                    mode: .outlineOnly
                                                )
                                            )
                                        }
                                        .sheet(
                                            isPresented: $shouldPresentSheet
                                        ) {
                                            AboutView()
                                                .presentationDetents(
                                                    [ .large]
                                                ) // Customize height
                                                .presentationBackground(
                                                    .clear
                                                ) // Ensure transparency
                                                .presentationDragIndicator(
                                                    .visible
                                                )
                                                .presentationCornerRadius(30)
                                                .onDisappear {
                                                
                                                }
                                        
                                        }
                                    //
                                    
                                }.overlay(
                                    Ellipse()
                                        .fill(currentColor)
                                        .frame(width: 300, height: 120)
                                        .blur(radius: 100)
                                        .blendMode(.plusLighter)
                                        .offset(y: -130)
                                        .opacity(isLightOn ? 0.3 : 0)
                                )
                                
                            }
                            Spacer()
                            // All slider
                            ZStack {
                                
                                ZStack{
                                    
                                    VStack {
                                        
                                        VStack {
                                            ZStack{
                                                Text("Controls")
                                                    .font(.system(size: 18))
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(
                                                        Color(hex: "#FFFFFF")
                                                            .opacity(0.2)
                                                    )
                                                    .padding(12)
                                            }
                                            
                                            ZStack {
                                                GradientSlider(
                                                    value: $numberValue,
                                                    currentColor: $currentColor,
                                                    range: 10...60,
                                                    gradientStops: gradientStops
                                                    
                                                )
                                                .onChange(
                                                    of: numberValue
                                                ) {
                                                    newValue,
                                                    _ in
                                                    if isLightOn && newValue >= 10 {
                                                        riveBulb
                                                            .setInput(
                                                                "ColorValue",
                                                                value: newValue
                                                            )
                                                    }
                                                }
                                                .onAppear {
                                                    riveBulb
                                                        .setInput(
                                                            "ColorValue",
                                                            value: numberValue
                                                        )
                                                    riveBulb
                                                        .setInput(
                                                            "on",
                                                            value: isLightOn
                                                        )
                                                }
                                            }
                                            .padding(.top, 4)
                                            .modifier(
                                                DebugLayoutModifier(
                                                    debug: debugLayout,
                                                    mode: .outlineOnly
                                                )
                                            )
                                            ZStack {
                                                OpacitySlider(
                                                    opacity: $opacity,
                                                    currentColor: $currentOpacityColor, // Pass the binding
                                                    isLightOn: isLightOn
                                                )
                                                
                                                
                                            }
                                            .padding(.top, 16)
                                            .modifier(
                                                DebugLayoutModifier(
                                                    debug: debugLayout,
                                                    mode: .outlineOnly
                                                )
                                            )
                                        }
                                        .padding(.leading, 40)
                                        .padding(.trailing, 40)
                                        .padding(.top, 10)
                                        .frame(width: geometry.size.width)
                                        
                                        

                                        ZStack {
                                            Button(
                                                action: {
                                                    isLightOn.toggle()
                                                    // Haptic feedback on present
                                                    let generator = UIImpactFeedbackGenerator(
                                                        style: .soft
                                                    )
                                                    generator.impactOccurred()
                                                    if isLightOn {
                                                        riveBulb
                                                            .setInput(
                                                                "ColorValue",
                                                                value: numberValue
                                                            )
                                                        riveBulb
                                                            .setInput(
                                                                "on",
                                                                value: isLightOn
                                                            )
                                                    } else {
                                                        riveBulb
                                                            .setInput(
                                                                "ColorValue",
                                                                value: Float(0)
                                                            )
                                                        riveBulb
                                                            .setInput(
                                                                "on",
                                                                value: isLightOn
                                                            )
                                                    }
                                                }) {
                                                    ZStack {

                                                        // Main button
                                                        ZStack {
                                                            //shadow
                                                            Circle()
                                                                .fill(
                                                                    .black
                                                                        .opacity(
                                                                            0.8
                                                                        )
                                                                )
                                                                .offset(
                                                                    y: isLightOn ? 1 : 8
                                                                )
                                                                .blur(
                                                                    radius: isLightOn ? 1 : 6
                                                                )
                                                            Circle()
                                                                .fill(
                                                                    LinearGradient(
                                                                        colors: [
                                                                            Color(
                                                                                hex: isLightOn ? "#222838" : "#191D21"
                                                                            ),
                                                                            Color(
                                                                                hex: "#111415"
                                                                            )
                                                                        ],
                                                                        startPoint: .top,
                                                                        endPoint: .bottom
                                                                    )
                                                                )
                                                        
                                                                .stroke(
                                                                    Color.black
                                                                        .opacity(
                                                                            1
                                                                        ),
                                                                    lineWidth: 0.5
                                                                )
                                                                .overlay(
                                                                    Circle()
                                                                        .stroke(
                                                                            Color.white
                                                                                .opacity(
                                                                                    isLightOn ? 0.2 : 0.1
                                                                                ),
                                                                            lineWidth: 1
                                                                        )
                                                                        .offset(
                                                                            x: 0,
                                                                            y: 0.5
                                                                        )
                                                                        .mask(
                                                                            Circle()
                                                                                .fill(
                                                                                    LinearGradient(
                                                                                        colors: [
                                                                                            .white,
                                                                                            .clear
                                                                                        ],
                                                                                        startPoint: .top,
                                                                                        endPoint: .bottom
                                                                                    )
                                                                                )
                                                                        )
                                                                ) // Inner shadow
                                                            
                                                        }
                                                        .frame(width: 60)
                                                    }
                                                    .frame(width: 80)
                                                    .overlay(
                                                        ZStack {
                                                            if isLightOn {
                                                                Image(
                                                                    systemName: "power"
                                                                )
                                                                .foregroundColor(
                                                                    isLightOn ? .white : .black
                                                                )
                                                                .font(
                                                                    .system(
                                                                        size: 18,
                                                                        weight: .bold
                                                                    )
                                                                )
                                                                .blur(radius: 3)
                                                            }
                                                            Image(
                                                                systemName: "power"
                                                            )
                                                            .foregroundColor(
                                                                isLightOn ? .white : .white
                                                                    .opacity(
                                                                        0.5
                                                                    )
                                                            )
                                                            .font(
                                                                .system(
                                                                    size: 18,
                                                                    weight: .bold
                                                                )
                                                            )
                                                        }
                                                    
                                                    )
                                                    .contentShape(Circle())
                                                }
                                                .buttonStyle(
                                                    NoOpacityButtonStyle()
                                                )
                                                .allowsHitTesting(true)
                                                .opacity(1.0)
                                                .animation(
                                                    nil,
                                                    value: isLightOn
                                                ) // Disable animation effect
                                        }
                                        .padding(.top, 16)
                                        .padding(
                                            .bottom,
                                            usableScreenHeight * 0.05
                                        )
                                        .modifier(
                                            DebugLayoutModifier(
                                                debug: debugLayout,
                                                mode: .outlineOnly
                                            )
                                        )
                                        
                                    }
                                }
                                //control background
                                .background(
                                    ZStack {
                                        Ellipse()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(
                                                        stops: gradientStops
                                                    ),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: 320, height: 100)
                                            .blur(radius: 6)
                                            .offset(y: -20)
                                        
                                        BlurView(
                                            style: .systemThinMaterial
                                        ) // Custom BlurView
                                        // Gradient Overlay
                                        LinearGradient(
                                            gradient: Gradient(
                                                colors: [
                                                    Color(hex: "#000000")
                                                        .opacity(0.3),
                                                    Color(hex: "#000000")
                                                        .opacity(0.8)
                                                ]
                                            ),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .overlay(
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 32)
                                            .strokeBorder(
                                                LinearGradient(
                                                    gradient: Gradient(
                                                        colors: [
                                                            Color(
                                                                hex: "#5D5D5D"
                                                            )
                                                            .opacity(0.5),
                                                            Color(
                                                                hex: "#5D5D5D"
                                                            )
                                                            .opacity(0.0)
                                                        ]
                                                    ),
                                                    startPoint: .top,
                                                    endPoint: UnitPoint(
                                                        x: 0.5,
                                                        y: 0.5
                                                    )
                                                ),
                                                lineWidth: 1 // Border thickness
                                            )
                                    }
                                    
                                )
                                //                                .modifier(DebugLayoutModifier(debug: debugLayout))
                            }
                            .modifier(
                                DebugLayoutModifier(
                                    debug: debugLayout,
                                    mode: .outlineOnly
                                )
                            )
                           
                        }
                        
                        .padding(.top, usableScreenHeight * 0.1)

                        
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
            
            LinearGradient(
                gradient: Gradient(
                    colors: [
                        Color(hex: "#000000").opacity(0.5),
                        Color(hex: "#000000").opacity(0.8)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            ).background(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack {
                VStack {
                    Image("rive-light")
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                    
                }
                ZStack {
                    VStack {
                        Text(
                            "I was just playing around with SwiftUI and Rive and made this little app as a test."
                        )
                        .font(.body)
                        .padding()
                        Text(
                            "The source code is available on GitHub, and the Rive file can be found in the community."
                        )
                        .font(.body)
                        .padding()
                        Text(
                            "I'd love to hear your feedback! Feel free to use it in any of your projects."
                        )
                        .font(.body)
                        .padding(12)
                    }
                    
                }.frame(width: 280)
                    .padding(12)
                HStack{
                    ZStack{
                        VStack{
                            Text("Designed and Developed by")
                                .font(.system(size: 14))
                                .opacity(0.7)
                            Image("realvjy")
                                .opacity(1)
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                            HStack{
                                Link(
                                    "Twitter",
                                    destination: URL(
                                        string: "https://www.x.com/realvjy"
                                    )!
                                )
                                .font(.system(size: 15)).opacity(0.9)
                                .foregroundStyle(Color(Color(hex: "1B90FF")))
                                .padding(6)
                                Link(
                                    "Github",
                                    destination: URL(
                                        string: "https://github.com/realvjy/light-controller-rive-swiftui"
                                    )!
                                )
                                .foregroundStyle(Color(Color(hex: "1B90FF")))
                                .font(.system(size: 15)).opacity(0.9)
                            }
                        }
                    }
                }
                .padding(.top, 24)
                
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

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

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
