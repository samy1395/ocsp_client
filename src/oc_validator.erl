-module(oc_validator).
-export([validate_cert/5]).
-include("OCSP.hrl").

validate_cert(PeerCert, CAChain, RequestorCert, RequestorPrivateKey, ProviderURL) ->
    CertID = oc_request_assembler:assemble_cert_id(PeerCert, CAChain),
    Nonce = oc_nonce:generate(),
    RequestBytes = oc_request_assembler:assemble_request(CertID, RequestorCert, RequestorPrivateKey, Nonce),
    case httpc:request(post, {ProviderURL, [], "application/ocsp-request", RequestBytes}, [], []) of
        {ok, {{_Version, HttpCode, Description}, _Headers, Response}} ->
            case HttpCode of
                200 -> oc_response_validator:validate(Response, CertID, Nonce);
                _   -> {error, {ocsp, {HttpCode, Description, Response}}}
            end;
        {error, Reason} ->
            {error, {ocsp, Reason}}
    end.

