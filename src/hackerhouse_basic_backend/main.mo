// import the custom types we have in Types.mo
import Types "types";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Map "mo:map/Map";
import { phash; nhash } "mo:map/Map";
import Principal "mo:base/Principal";
import Vector "mo:vector";

type UserCompleteProfile = {
    name : Text;
    socials_linkedin : Text;
    socials_twitter : Text;
    socials_github : Text;
};

actor {
    stable var autoIndex = 0;
    let userIdMap = Map.new<Principal, Nat>();
    let userProfileMap = Map.new<Nat, Text>();
    let userResultsMap = Map.new<Nat, Vector.Vector<Text>>();
    let userCompleteProfileMap = Map.new<Nat, UserCompleteProfile>();

    public query ({ caller }) func getCurrentUserIdentity() : async Principal {
        return caller;
    };

    public query ({ caller }) func checkIfLoggedIn() : async Text {
        if (caller == Principal.fromText("2vxsx-fae")) {
            return "You are using \"2vxsx-fae\", which is the anonymous principal. You should authenticate.";
        } else {
            return "Looks good! Your Principal is a distinct one.";
        };
    };

    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let maybeUserId = Map.get(userIdMap, phash, caller);
        switch (maybeUserId) {
            case (?userId) {
                let maybeProfile = Map.get(userProfileMap, nhash, userId);
                switch (maybeProfile) {
                    case (?name) {
                        return #ok({ id = userId; name = name });
                    };
                    case (_) {
                        return #err("Profile not found for user");
                    };
                };
            };
            case (_) {
                return #err("You are not registered, use setUserProfile to set your profile");
            };
        };
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        switch (Map.get(userIdMap, phash, caller)) {
            case (?x) {};
            case (_) {
                // set user id
                Map.set(userIdMap, phash, caller, autoIndex);
                // increment for next user
                autoIndex += 1;
            };
        };

        // set profile name
        let foundId = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) found;
            case (_) { return #err("User not found") };
        };

        Map.set(userProfileMap, nhash, foundId, name);

        return #ok({ id = foundId; name = name });
    };

    public query func getUserProfileById(id : Nat) : async Result.Result<{ id : Nat; name : Text }, Text> {
        let maybeProfile = Map.get(userProfileMap, nhash, id);
        switch (maybeProfile) {
            case (?name) {
                return #ok({ id = id; name = name });
            };
            case (_) {
                return #err("Profile not found for the given ID");
            };
        };
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        let userId = switch (Map.get(userIdMap, phash, caller)) {
            case (?found) found;
            case (_) return #err("User not found");
        };

        let results = switch (Map.get(userResultsMap, nhash, userId)) {
            case (?found) found;
            case (_) Vector.new<Text>();
        };

        Vector.add(results, result);
        Map.set(userResultsMap, nhash, userId, results);

        return #ok({ id = userId; results = Vector.toArray(results) });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {

        let maybeUserId = Map.get(userIdMap, phash, caller);
        let userId = switch (maybeUserId) {
            case (?id) id;
            case (_) return #err("User not registered");
        };

        let maybeResults = Map.get(userResultsMap, nhash, userId);
        let results = switch (maybeResults) {
            case (?res) Vector.toArray(res);
            case (_) [];
        };

        return #ok({ id = userId; results = results });
    };

    public shared ({ caller }) func setUserCompleteProfile(
        name : Text,
        socials_linkedin : Text,
        socials_twitter : Text,
        socials_github : Text,
    ) : async Result.Result<{ id : Nat; profile : UserCompleteProfile }, Text> {

        let maybeUserId = Map.get(userIdMap, phash, caller);
        let userId = switch (maybeUserId) {
            case (?id) id;
            case (_) return #err("User not registered");
        };

        let profile : UserCompleteProfile = {
            name = name;
            socials_linkedin = socials_linkedin;
            socials_twitter = socials_twitter;
            socials_github = socials_github;
        };

        Map.set(userCompleteProfileMap, nhash, userId, profile);

        return #ok({ id = userId; profile = profile });
    };

    public query func getUserCompleteProfile(id : Nat) : async Result.Result<UserCompleteProfile, Text> {
        let maybeProfile = Map.get(userCompleteProfileMap, nhash, id);
        switch (maybeProfile) {
            case (?profile) {
                return #ok(profile);
            };
            case (_) {
                return #err("Profile not found for the given user ID");
            };
        };
    };

    public func outcall_ai_model_for_sentiment_analysis(paragraph : Text) : async Result.Result<{ paragraph : Text; result : Text }, Text> {
        let host = "api-inference.huggingface.co";
        let path = "/models/cardiffnlp/twitter-roberta-base-sentiment-latest";

        let headers = [
            {
                name = "Authorization";
                value = "Bearer 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";
            },
            { name = "Content-Type"; value = "application/json" },
        ];

        let body_json : Text = "{ \"inputs\" : \" " # paragraph # "\" }";

        let text_response = await make_post_http_outcall(host, path, headers, body_json);

        // TODO
        // Install "serde" package and parse JSON
        // calculate highest sentiment and return it as a result

        return #ok({
            paragraph = paragraph;
            result = text_response;
        });
    };

    // NOTE: don't edit below this line

    // Function to transform the HTTP response
    // This function can't be private because it's shared with the IC management canister
    // but it's usage, is not meant to be exposed to the frontend
    public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
        let transformed : Types.CanisterHttpResponsePayload = {
            status = raw.response.status;
            body = raw.response.body;
            headers = [
                {
                    name = "Content-Security-Policy";
                    value = "default-src 'self'";
                },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                {
                    name = "Strict-Transport-Security";
                    value = "max-age=63072000";
                },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ];
        };
        transformed;
    };

    func make_post_http_outcall(host : Text, path : Text, headers : [Types.HttpHeader], body_json : Text) : async Text {
        //1. DECLARE IC MANAGEMENT CANISTER
        //We need this so we can use it to make the HTTP request
        let ic : Types.IC = actor ("aaaaa-aa");

        //2. SETUP ARGUMENTS FOR HTTP GET request
        // 2.1 Setup the URL and its query parameters
        let url = "https://" # host # path;

        // 2.2 prepare headers for the system http_request call
        let request_headers = [
            { name = "Host"; value = host # ":443" },
            { name = "User-Agent"; value = "hackerhouse_canister" },
        ];

        let merged_headers = Array.flatten<Types.HttpHeader>([request_headers, headers]);

        // 2.2.1 Transform context
        let transform_context : Types.TransformContext = {
            function = transform;
            context = Blob.fromArray([]);
        };

        // The request body is an array of [Nat8] (see Types.mo) so do the following:
        // 1. Write a JSON string
        // 2. Convert ?Text optional into a Blob, which is an intermediate representation before you cast it as an array of [Nat8]
        // 3. Convert the Blob into an array [Nat8]
        let request_body_as_Blob : Blob = Text.encodeUtf8(body_json);
        let request_body_as_nat8 : [Nat8] = Blob.toArray(request_body_as_Blob);

        // 2.3 The HTTP request
        let http_request : Types.HttpRequestArgs = {
            url = url;
            max_response_bytes = null; //optional for request
            headers = request_headers;
            // note: type of `body` is ?[Nat8] so it is passed here as "?request_body_as_nat8" instead of "request_body_as_nat8"
            body = ?request_body_as_nat8;
            method = #post;
            transform = ?transform_context;
        };

        //3. ADD CYCLES TO PAY FOR HTTP REQUEST

        //The IC specification spec says, "Cycles to pay for the call must be explicitly transferred with the call"
        //IC management canister will make the HTTP request so it needs cycles
        //See: https://internetcomputer.org/docs/current/motoko/main/cycles

        //The way Cycles.add() works is that it adds those cycles to the next asynchronous call
        //"Function add(amount) indicates the additional amount of cycles to be transferred in the next remote call"
        //See: https://internetcomputer.org/docs/current/references/ic-interface-spec/#ic-http_request
        Cycles.add<system>(230_949_972_000);

        //4. MAKE HTTPS REQUEST AND WAIT FOR RESPONSE
        //Since the cycles were added above, we can just call the IC management canister with HTTPS outcalls below
        let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);

        //5. DECODE THE RESPONSE

        //As per the type declarations in `src/Types.mo`, the BODY in the HTTP response
        //comes back as [Nat8s] (e.g. [2, 5, 12, 11, 23]). Type signature:

        //public type HttpResponsePayload = {
        //     status : Nat;
        //     headers : [HttpHeader];
        //     body : [Nat8];
        // };

        //We need to decode that [Nat8] array that is the body into readable text.
        //To do this, we:
        //  1. Convert the [Nat8] into a Blob
        //  2. Use Blob.decodeUtf8() method to convert the Blob to a ?Text optional
        //  3. We use a switch to explicitly call out both cases of decoding the Blob into ?Text
        let response_body : Blob = Blob.fromArray(http_response.body);
        let decoded_text : Text = switch (Text.decodeUtf8(response_body)) {
            case (null) { "No value returned" };
            case (?y) { y };
        };

        // 6. RETURN RESPONSE OF THE BODY
        return decoded_text;
    };
};
