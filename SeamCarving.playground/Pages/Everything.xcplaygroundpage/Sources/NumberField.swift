import SwiftUI
import Combine

public struct NumberField: View {
    
    init(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) {
        self._numberValue = value
        self._stringValue = State.init(initialValue: "\(value)")
        self._title = State.init(initialValue: title)
        self.range = range
    }
    
    @Binding var numberValue: Int
    @State private var stringValue: String
    @State private var title: String
    var range: ClosedRange<Int>
    
    public var body: some View {
        HStack {
            Text("\(title): ")
            TextField(title, text: $stringValue)
                .labelsHidden()
                .frame(maxWidth: 75)
                .onReceive(Just(stringValue)) { newValue in
                    guard let num = Int(newValue), range.contains(num) else {
                        self.stringValue = String(numberValue)
                        return
                    }
                    numberValue = num
                }
        }
    }
}
