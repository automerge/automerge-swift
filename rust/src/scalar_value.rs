use automerge as am;

pub enum ScalarValue {
    Bytes { value: Vec<u8> },
    String { value: String },
    Int { value: i64 },
    Uint { value: u64 },
    F64 { value: f64 },
    Counter { value: i64 },
    Timestamp { value: i64 },
    Boolean { value: bool },
    Unknown { type_code: u8, data: Vec<u8> },
    Null,
}

impl From<ScalarValue> for am::ScalarValue {
    fn from(value: ScalarValue) -> Self {
        match value {
            ScalarValue::Bytes { value } => am::ScalarValue::Bytes(value),
            ScalarValue::String { value } => am::ScalarValue::Str(value.into()),
            ScalarValue::Int { value } => am::ScalarValue::Int(value),
            ScalarValue::Uint { value } => am::ScalarValue::Uint(value),
            ScalarValue::F64 { value } => am::ScalarValue::F64(value),
            ScalarValue::Counter { value } => am::ScalarValue::Counter(value.into()),
            ScalarValue::Timestamp { value } => am::ScalarValue::Timestamp(value),
            ScalarValue::Boolean { value } => am::ScalarValue::Boolean(value),
            ScalarValue::Unknown { type_code, data } => am::ScalarValue::Unknown {
                type_code,
                bytes: data,
            },
            ScalarValue::Null => am::ScalarValue::Null,
        }
    }
}

impl<'a> From<&'a am::ScalarValue> for ScalarValue {
    fn from(value: &'a am::ScalarValue) -> Self {
        match value {
            am::ScalarValue::Bytes(b) => ScalarValue::Bytes { value: b.clone() },
            am::ScalarValue::Str(s) => ScalarValue::String {
                value: s.to_string(),
            },
            am::ScalarValue::Int(i) => ScalarValue::Int { value: *i },
            am::ScalarValue::Uint(u) => ScalarValue::Uint { value: *u },
            am::ScalarValue::F64(f) => ScalarValue::F64 { value: *f },
            am::ScalarValue::Counter(i) => ScalarValue::Counter { value: i.into() },
            am::ScalarValue::Timestamp(i) => ScalarValue::Timestamp { value: *i },
            am::ScalarValue::Boolean(b) => ScalarValue::Boolean { value: *b },
            am::ScalarValue::Unknown { type_code, bytes } => ScalarValue::Unknown {
                type_code: *type_code,
                data: bytes.clone(),
            },
            am::ScalarValue::Null => ScalarValue::Null,
        }
    }
}
