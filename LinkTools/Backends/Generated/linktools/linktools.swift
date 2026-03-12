public func mac_random_local() -> MACAddress {
    MACAddress(ptr: __swift_bridge__$mac_random_local())
}
public func mac_random_with_vendor<GenericToRustStr: ToRustStr>(_ vendor_id: GenericToRustStr) -> Optional<MACAddress> {
    return vendor_id.toRustStr({ vendor_idAsRustStr in
        { let val = __swift_bridge__$mac_random_with_vendor(vendor_idAsRustStr); if val != nil { return MACAddress(ptr: val!) } else { return nil } }()
    })
}
public func batch_validate_macs<GenericIntoRustString: IntoRustString>(_ addrs: RustVec<GenericIntoRustString>) -> RustVec<Bool> {
    RustVec(ptr: __swift_bridge__$batch_validate_macs({ let val = addrs; val.isOwned = false; return val.ptr }()))
}
public func batch_normalize_macs<GenericIntoRustString: IntoRustString>(_ addrs: RustVec<GenericIntoRustString>) -> RustVec<RustString> {
    RustVec(ptr: __swift_bridge__$batch_normalize_macs({ let val = addrs; val.isOwned = false; return val.ptr }()))
}
public func batch_anonymize_macs<GenericIntoRustString: IntoRustString>(_ addrs: RustVec<GenericIntoRustString>) -> RustVec<RustString> {
    RustVec(ptr: __swift_bridge__$batch_anonymize_macs({ let val = addrs; val.isOwned = false; return val.ptr }()))
}
public func batch_generate_local_macs(_ count: UInt) -> RustVec<RustString> {
    RustVec(ptr: __swift_bridge__$batch_generate_local_macs(count))
}
public func batch_generate_vendor_macs<GenericToRustStr: ToRustStr>(_ vendor_id: GenericToRustStr, _ count: UInt) -> RustVec<RustString> {
    return vendor_id.toRustStr({ vendor_idAsRustStr in
        RustVec(ptr: __swift_bridge__$batch_generate_vendor_macs(vendor_idAsRustStr, count))
    })
}
public func mac_similarity_score<GenericToRustStr: ToRustStr>(_ mac1: GenericToRustStr, _ mac2: GenericToRustStr) -> Optional<Double> {
    return mac2.toRustStr({ mac2AsRustStr in
        return mac1.toRustStr({ mac1AsRustStr in
        __swift_bridge__$mac_similarity_score(mac1AsRustStr, mac2AsRustStr).intoSwiftRepr()
    })
    })
}
public func mac_are_same_vendor<GenericToRustStr: ToRustStr>(_ mac1: GenericToRustStr, _ mac2: GenericToRustStr) -> Bool {
    return mac2.toRustStr({ mac2AsRustStr in
        return mac1.toRustStr({ mac1AsRustStr in
        __swift_bridge__$mac_are_same_vendor(mac1AsRustStr, mac2AsRustStr)
    })
    })
}
public enum LinkError {
    case InvalidFormat
}
extension LinkError {
    func intoFfiRepr() -> __swift_bridge__$LinkError {
        switch self {
            case LinkError.InvalidFormat:
                return __swift_bridge__$LinkError(tag: __swift_bridge__$LinkError$InvalidFormat)
        }
    }
}
extension __swift_bridge__$LinkError {
    func intoSwiftRepr() -> LinkError {
        switch self.tag {
            case __swift_bridge__$LinkError$InvalidFormat:
                return LinkError.InvalidFormat
            default:
                fatalError("Unreachable")
        }
    }
}
extension __swift_bridge__$Option$LinkError {
    @inline(__always)
    func intoSwiftRepr() -> Optional<LinkError> {
        if self.is_some {
            return self.val.intoSwiftRepr()
        } else {
            return nil
        }
    }
    @inline(__always)
    static func fromSwiftRepr(_ val: Optional<LinkError>) -> __swift_bridge__$Option$LinkError {
        if let v = val {
            return __swift_bridge__$Option$LinkError(is_some: true, val: v.intoFfiRepr())
        } else {
            return __swift_bridge__$Option$LinkError(is_some: false, val: __swift_bridge__$LinkError())
        }
    }
}
extension LinkError: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_LinkError$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_LinkError$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Self) {
        __swift_bridge__$Vec_LinkError$push(vecPtr, value.intoFfiRepr())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_LinkError$pop(vecPtr)
        return maybeEnum.intoSwiftRepr()
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_LinkError$get(vecPtr, index)
        return maybeEnum.intoSwiftRepr()
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<Self> {
        let maybeEnum = __swift_bridge__$Vec_LinkError$get_mut(vecPtr, index)
        return maybeEnum.intoSwiftRepr()
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<Self> {
        UnsafePointer<Self>(OpaquePointer(__swift_bridge__$Vec_LinkError$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_LinkError$len(vecPtr)
    }
}

public class MACAddress: MACAddressRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$MACAddress$_free(ptr)
        }
    }
}
extension MACAddress {
    public convenience init<GenericToRustStr: ToRustStr>(_ input: GenericToRustStr) throws {
        input.toRustStr({ inputAsRustStr in
            let val = __swift_bridge__$MACAddress$parse(inputAsRustStr); if val.tag == __swift_bridge__$ResultMACAddressAndLinkError$ResultOk { self.init(ptr: val.payload.ok) } else { throw val.payload.err.intoSwiftRepr() }
        })
    }
}
public class MACAddressRefMut: MACAddressRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class MACAddressRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension MACAddressRef {
    public func to_string() -> RustString {
        RustString(ptr: __swift_bridge__$MACAddress$to_string(ptr))
    }

    public func anonymize() -> RustString {
        RustString(ptr: __swift_bridge__$MACAddress$anonymize(ptr))
    }

    public func to_oui() -> Oui {
        Oui(ptr: __swift_bridge__$MACAddress$to_oui(ptr))
    }

    public func lookup_vendor() -> Optional<RustString> {
        { let val = __swift_bridge__$MACAddress$lookup_vendor(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }
}
extension MACAddress: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_MACAddress$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_MACAddress$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: MACAddress) {
        __swift_bridge__$Vec_MACAddress$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_MACAddress$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (MACAddress(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<MACAddressRef> {
        let pointer = __swift_bridge__$Vec_MACAddress$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return MACAddressRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<MACAddressRefMut> {
        let pointer = __swift_bridge__$Vec_MACAddress$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return MACAddressRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<MACAddressRef> {
        UnsafePointer<MACAddressRef>(OpaquePointer(__swift_bridge__$Vec_MACAddress$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_MACAddress$len(vecPtr)
    }
}


public class Oui: OuiRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Oui$_free(ptr)
        }
    }
}
extension Oui {
    public convenience init<GenericToRustStr: ToRustStr>(_ input: GenericToRustStr) throws {
        input.toRustStr({ inputAsRustStr in
            let val = __swift_bridge__$Oui$parse(inputAsRustStr); if val.tag == __swift_bridge__$ResultOuiAndLinkError$ResultOk { self.init(ptr: val.payload.ok) } else { throw val.payload.err.intoSwiftRepr() }
        })
    }
}
public class OuiRefMut: OuiRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class OuiRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension OuiRef {
    public func to_string() -> RustString {
        RustString(ptr: __swift_bridge__$Oui$to_string(ptr))
    }

    public func lookup_vendor() -> Optional<RustString> {
        { let val = __swift_bridge__$Oui$lookup_vendor(ptr); if val != nil { return RustString(ptr: val!) } else { return nil } }()
    }

    public func to_hex_string() -> RustString {
        RustString(ptr: __swift_bridge__$Oui$to_hex_string(ptr))
    }
}
extension Oui: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Oui$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Oui$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Oui) {
        __swift_bridge__$Vec_Oui$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Oui$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Oui(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<OuiRef> {
        let pointer = __swift_bridge__$Vec_Oui$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return OuiRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<OuiRefMut> {
        let pointer = __swift_bridge__$Vec_Oui$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return OuiRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<OuiRef> {
        UnsafePointer<OuiRef>(OpaquePointer(__swift_bridge__$Vec_Oui$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Oui$len(vecPtr)
    }
}


public class Bssid: BssidRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Bssid$_free(ptr)
        }
    }
}
extension Bssid {
    public convenience init<GenericToRustStr: ToRustStr>(_ input: GenericToRustStr) throws {
        input.toRustStr({ inputAsRustStr in
            let val = __swift_bridge__$Bssid$parse(inputAsRustStr); if val.tag == __swift_bridge__$ResultBssidAndLinkError$ResultOk { self.init(ptr: val.payload.ok) } else { throw val.payload.err.intoSwiftRepr() }
        })
    }
}
public class BssidRefMut: BssidRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class BssidRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension BssidRef {
    public func to_string() -> RustString {
        RustString(ptr: __swift_bridge__$Bssid$to_string(ptr))
    }

    public func to_mac() -> MACAddress {
        MACAddress(ptr: __swift_bridge__$Bssid$to_mac(ptr))
    }

    public func is_hidden_ssid_indicator() -> Bool {
        __swift_bridge__$Bssid$is_hidden_ssid_indicator(ptr)
    }
}
extension Bssid: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Bssid$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Bssid$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Bssid) {
        __swift_bridge__$Vec_Bssid$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Bssid$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Bssid(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<BssidRef> {
        let pointer = __swift_bridge__$Vec_Bssid$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return BssidRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<BssidRefMut> {
        let pointer = __swift_bridge__$Vec_Bssid$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return BssidRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<BssidRef> {
        UnsafePointer<BssidRef>(OpaquePointer(__swift_bridge__$Vec_Bssid$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Bssid$len(vecPtr)
    }
}


public class Ssid: SsidRefMut {
    var isOwned: Bool = true

    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }

    deinit {
        if isOwned {
            __swift_bridge__$Ssid$_free(ptr)
        }
    }
}
extension Ssid {
    public convenience init<GenericToRustStr: ToRustStr>(_ input: GenericToRustStr) throws {
        input.toRustStr({ inputAsRustStr in
            let val = __swift_bridge__$Ssid$parse(inputAsRustStr); if val.tag == __swift_bridge__$ResultSsidAndLinkError$ResultOk { self.init(ptr: val.payload.ok) } else { throw val.payload.err.intoSwiftRepr() }
        })
    }
}
public class SsidRefMut: SsidRef {
    public override init(ptr: UnsafeMutableRawPointer) {
        super.init(ptr: ptr)
    }
}
public class SsidRef {
    var ptr: UnsafeMutableRawPointer

    public init(ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }
}
extension SsidRef {
    public func to_string() -> RustString {
        RustString(ptr: __swift_bridge__$Ssid$to_string(ptr))
    }

    public func is_hidden() -> Bool {
        __swift_bridge__$Ssid$is_hidden(ptr)
    }

    public func is_valid() -> Bool {
        __swift_bridge__$Ssid$is_valid(ptr)
    }

    public func is_carrier_wifi() -> Bool {
        __swift_bridge__$Ssid$is_carrier_wifi(ptr)
    }

    public func is_public_hotspot() -> Bool {
        __swift_bridge__$Ssid$is_public_hotspot(ptr)
    }
}
extension Ssid: Vectorizable {
    public static func vecOfSelfNew() -> UnsafeMutableRawPointer {
        __swift_bridge__$Vec_Ssid$new()
    }

    public static func vecOfSelfFree(vecPtr: UnsafeMutableRawPointer) {
        __swift_bridge__$Vec_Ssid$drop(vecPtr)
    }

    public static func vecOfSelfPush(vecPtr: UnsafeMutableRawPointer, value: Ssid) {
        __swift_bridge__$Vec_Ssid$push(vecPtr, {value.isOwned = false; return value.ptr;}())
    }

    public static func vecOfSelfPop(vecPtr: UnsafeMutableRawPointer) -> Optional<Self> {
        let pointer = __swift_bridge__$Vec_Ssid$pop(vecPtr)
        if pointer == nil {
            return nil
        } else {
            return (Ssid(ptr: pointer!) as! Self)
        }
    }

    public static func vecOfSelfGet(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<SsidRef> {
        let pointer = __swift_bridge__$Vec_Ssid$get(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return SsidRef(ptr: pointer!)
        }
    }

    public static func vecOfSelfGetMut(vecPtr: UnsafeMutableRawPointer, index: UInt) -> Optional<SsidRefMut> {
        let pointer = __swift_bridge__$Vec_Ssid$get_mut(vecPtr, index)
        if pointer == nil {
            return nil
        } else {
            return SsidRefMut(ptr: pointer!)
        }
    }

    public static func vecOfSelfAsPtr(vecPtr: UnsafeMutableRawPointer) -> UnsafePointer<SsidRef> {
        UnsafePointer<SsidRef>(OpaquePointer(__swift_bridge__$Vec_Ssid$as_ptr(vecPtr)))
    }

    public static func vecOfSelfLen(vecPtr: UnsafeMutableRawPointer) -> UInt {
        __swift_bridge__$Vec_Ssid$len(vecPtr)
    }
}



