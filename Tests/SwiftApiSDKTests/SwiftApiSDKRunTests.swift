//
//  UpcomingMoviesApiTests.swift
//  UpcomingMoviesApiTests
//
//  Created by FMMobile on 19/05/2019.
//  Copyright © 2019 FMMobile. All rights reserved.
//

import XCTest
@testable import SwiftApiSDK
import OHHTTPStubs
import OHHTTPStubsSwift

class SwiftApiSDKExecuteTests: XCTestCase {
    private enum StubEndPoint: EndPoint {
        case basic
        func path() -> SwiftApiSDK.Path {
            ""
        }
        
        func header() -> SwiftApiSDK.Header {
            [:]
        }
        
        func contentType() -> SwiftApiSDK.ContentType {
            .json
        }
        
        func method() -> SwiftApiSDK.HttpMethod {
            .GET
        }
    }

    override func setUp() {
        HTTPStubs.setEnabled(true)
        HTTPStubs.onStubActivation { (request: URLRequest, stub: HTTPStubsDescriptor, _: HTTPStubsResponse) in
            print("[OHHTTPStubs] Request to \(request.url!) has been stubbed with \(String(describing: stub.name))")
        }
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testNovaApiRequest_MockGenreList_True() {
        
        stub(condition: isHost("api.themoviedb.org")) { _ in
            let stubPath = Bundle.module.url(forResource: "Genre", withExtension: "json")!.path
            return fixture(filePath: stubPath, status: 200, headers: ["Content-Type": "application/json"])
        }

        let api: ApiRestProtocol = ApiRunner()
        let promise = expectation(description: "Api Request")

        let params = GetParams(params: [:])
        api.run(param: ApiParamFactory.basic.generate(domain: WebDomainMock.self,
                                                      endPoint: StubEndPoint.basic,
                                                      params: params),
                GenreList.self) { result, request in
            switch result {
            case .success(let model):
                XCTAssertTrue(!model.genres.isEmpty)
                XCTAssert(request != nil)
            case .failure:
                XCTFail("Failure not allowed")
            }
            promise.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testNovaApiRequest_Status500_True() {
        stub(condition: isHost("api.themoviedb.org")) { _ in
            let stubPath = Bundle.module.url(forResource: "Genre",
                                             withExtension: "json")!.path
            return fixture(filePath: stubPath, status: 500, headers: ["Content-Type": "application/json"])
        }

        let api: ApiRestProtocol = ApiRunner()
        let promise = expectation(description: "Api Request")
        let params = GetParams(params: [:])
        api.run(param: ApiParamFactory.basic.generate(domain: WebDomainMock.self,
                                                      endPoint: StubEndPoint.basic,
                                                      params: params), GenreList.self) { result, _ in
            switch result {
            case .success:
                XCTFail("Failure not allowed")
            case .failure(let error):
                XCTAssertTrue(error == .statusCodeError(500))
            }
            promise.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testNovaApiRequest_MockGenreListError_True() {
        stub(condition: isHost("api.themoviedb.org")) { _ in
            let stubPath = Bundle.module.url(forResource: "GenreCorrupt",
                                             withExtension: "json")!.path
            return fixture(filePath: stubPath, status: 200, headers: ["Content-Type": "application/json"])
        }

        let api: ApiRestProtocol = ApiRunner()
        let promise = expectation(description: "Api Request")
        let params = GetParams(params: [:])
        api.run(param: ApiParamFactory.basic.generate(domain: WebDomainMock.self,
                                                      endPoint: StubEndPoint.basic,
                                                      params: params), GenreList.self) { result, _ in
            switch result {
            case .success:
                XCTFail("Failure not allowed")
            case .failure(let error):
                let nsError = NSError(domain: "", code: ApiErrorCodes.responseCodableFail.rawValue, userInfo: nil)
                XCTAssertTrue(error == .contentSerializeError(nsError))
            }
            promise.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    @available(iOS 15.0, *)
    func testNovaApiRequestAsync_MockGenreList_True() async throws {
        stub(condition: isHost("api.themoviedb.org")) { _ in
            let stubPath = Bundle.module.url(forResource: "Genre", withExtension: "json")!.path
            return fixture(filePath: stubPath, status: 200, headers: ["Content-Type": "application/json"])
        }

        let api: ApiRestAsyncProtocol = ApiRunner()
        let params = ApiParamFactory.basic.generate(domain: WebDomainMock.self,
                                                    endPoint: StubEndPoint.basic,
                                                    params: GetParams(params: [:]))
        let (model, request) = try await api.run(param: params,  GenreList.self)
        XCTAssertTrue(!model.genres.isEmpty)
        XCTAssert(request != nil)
    }
}
