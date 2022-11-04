import MapKit

// MKCircle only has convenience initializers, no designated ones.
// So it's really difficult to define a good subclass.
// We cannot define an initializer because that must
// call superclass designated initializer and there are none.
// So there is no way to initialize the properties being added here.
// They must have a default value in order to omit having an initializer,
// but the default values are not actually used.
class MyCircle: MKCircle {
    var alpha: Double = 0.0
    var fillColor: UIColor = .clear
    var lineWidth: Double = 0.0
    var strokeColor: UIColor = .clear
}
