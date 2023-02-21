import struct AutomergeUniffi.PathElement
import enum AutomergeUniffi.Prop

typealias FfiPathElem = AutomergeUniffi.PathElement
typealias FfiProp = AutomergeUniffi.Prop

public struct PathElement: Equatable {
  let prop: Prop
  let obj: ObjId

  public init(obj: ObjId, prop: Prop) {
    self.prop = prop
    self.obj = obj
  }

  static func fromFfi(_ ffiElem: FfiPathElem) -> Self {
    return Self(
      obj: ObjId(bytes: ffiElem.obj),
      prop: Prop.fromFfi(ffiElem.prop)
    )
  }
}

public enum Prop: Equatable {
  case Key(String)
  case Index(UInt64)

  static func fromFfi(_ ffi: FfiProp) -> Self {
    switch ffi {
    case .index(let value):
      return .Index(value)
    case .key(let value):
      return .Key(value)
    }
  }
}
