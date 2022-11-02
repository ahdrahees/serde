import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

import ActorSpec "./utils/ActorSpec";

import JSON "../src/JSON";
import Candid "../src/Candid";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

type User = {
    name : Text;
};

let success = run([
    describe(
        "JSON",
        [
            it(
                "fromText()",
                do {
                    let text = "{ \"name\" : \"Tomi\" }";
                    switch (JSON.fromText(text)) {
                        case (?blob) {
                            Debug.print(debug_show blob);
                            let user : ?User = from_candid (blob);
                            user == ?{ name = "Tomi" };
                        };
                        case (_) false;
                    };
                },
            ),

            it(
                "decode()",
                do {
                    let candid = #Record([("name", #Text("Tomi"))]);

                    let blob = Candid.decode(candid);
                    let user : ?User = from_candid (blob);

                    user == ?{ name = "Tomi" };
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
