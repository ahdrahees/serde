import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";

import Encoder "mo:motoko_candid/Encoder";
import Decoder "mo:motoko_candid/Decoder";

import Arg "mo:motoko_candid/Arg";
import Value "mo:motoko_candid/Value";
import Type "mo:motoko_candid/Type";
import Tag "mo:motoko_candid/Tag";

import { hashName } "mo:motoko_candid/Tag";

import T "Types";

module {
    type Arg = Arg.Arg;
    type Type = Type.Type;
    type Value = Value.Value;
    type RecordFieldType = Type.RecordFieldType;
    type RecordFieldValue = Value.RecordFieldValue;

    type Candid = T.Candid;
    type KeyValuePair = T.KeyValuePair;

    public func encode(blob : Blob, recordKeys : [Text]) : Candid {
        let res = Decoder.decode(blob);

        let keyEntries = Iter.map<Text, (Nat32, Text)>(
            recordKeys.vals(),
            func(key : Text) : (Nat32, Text) {
                (hashName(key), key);
            },
        );

        let recordKeyMap = TrieMap.fromEntries<Nat32, Text>(
            keyEntries,
            Nat32.equal,
            func(n : Nat32) : Hash.Hash {
                Hash.hash(Nat32.toNat(n));
            },
        );

        switch (res) {
            case (?args) {
                fromArgs(args, recordKeyMap);
            };
            case (_) { Prelude.unreachable() };
        };
    };

    func fromArgs(args : [Arg], recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        let arg = args[0];

        fromArgValue(arg.value, recordKeyMap);
    };

    func fromArgValue(val : Value, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Candid {
        switch (val) {
            case (#Nat(n)) #Nat(n);
            case (#Nat8(n)) #Nat8(n);
            case (#Nat16(n)) #Nat16(n);
            case (#Nat32(n)) #Nat32(n);
            case (#Nat64(n)) #Nat64(n);

            case (#Int(n)) #Int(n);
            case (#Int8(n)) #Int8(n);
            case (#Int16(n)) #Int16(n);
            case (#Int32(n)) #Int32(n);
            case (#Int64(n)) #Int64(n);

            case (#Float64(n)) #Float(n);

            case (#Bool(b)) #Bool(b);

            case (#Principal(service)) {
                switch (service) {
                    case (#transparent(p)) {
                        #Principal(p);
                    };
                    case (_) Prelude.unreachable();
                };
            };

            case (#Text(n)) #Text(n);

            case (#Null) #Null;

            case (#Option(optVal)) {
                let val = switch (optVal) {
                    case (?val) {
                        fromArgValue(val, recordKeyMap);
                    };
                    case (_) #Null;
                };

                #Option(val);
            };
            case (#Vector(arr)) {
                let newArr = Array.map(
                    arr,
                    func(elem : Value) : Candid {
                        fromArgValue(elem, recordKeyMap);
                    },
                );

                #Array(newArr);
            };

            case (#Record(records)) {
                let newRecords = Array.map(
                    records,
                    func({ tag; value } : RecordFieldValue) : KeyValuePair {
                        let key = getKey(tag, recordKeyMap);
                        let val = fromArgValue(value, recordKeyMap);

                        (key, val);
                    },
                );

                #Record(Array.sort(newRecords, cmpRecords));
            };

            // case (#Variant(variant)) {
            //     Debug.print(debug_show variant);

            //     let { tag; value } = variant;

            //     let key = getKey(tag, recordKeyMap);
            //     let candid_value = fromArgValue(value, recordKeyMap);

            //     #Variant((key, candid_value));
            // };

            case (_) { Prelude.unreachable() };
        };
    };

    func getKey(tag : Tag.Tag, recordKeyMap : TrieMap.TrieMap<Nat32, Text>) : Text {
        switch (tag) {
            case (#hash(hash)) {
                switch (recordKeyMap.get(hash)) {
                    case (?key) {
                        key;
                    };
                    case (_) {
                        debug_show hash;
                    };
                };
            };
            case (#name(key)) {
                key;
            };
        };
    };

    func cmpRecords(a : (Text, Any), b : (Text, Any)) : Order.Order {
        Text.compare(a.0, b.0);
    };
};
