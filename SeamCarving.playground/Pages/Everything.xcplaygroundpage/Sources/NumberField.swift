import SwiftUI
import Combine

public struct NumberField: View {
    
    init(_ title: String, value: Binding<Int>, max: Int) {
        self._numberValue = value
        self._stringValue = State.init(initialValue: "\(value)")
        self._title = State.init(initialValue: title)
        self.max = max
    }
    
    @Binding var numberValue: Int
    @State private var stringValue: String
    @State private var title: String
    var max: Int
    
    public var body: some View {
        HStack {
            Text("\(title): ")
            TextField(title, text: $stringValue)
                .labelsHidden()
                .frame(maxWidth: 75)
                .onReceive(Just(stringValue)) { newValue in
                    guard let num = Int(newValue), (0...max).contains(num) else {
                        self.stringValue = String(numberValue)
                        return
                    }
                    numberValue = num
                }
        }
    }
}
