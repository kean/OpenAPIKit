//
//  DefaultValidatorTests.swift
//  
//
//  Created by Mathew Polzin on 6/3/20.
//

import Foundation
import XCTest
import OpenAPIKit

final class DefaultValidatorTests: XCTestCase {
    func test_noPathsOnDocumentFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [:],
            components: .noComponents
        )

        let validator = Validator.blank.validating(.documentContainsPaths)

        XCTAssertThrowsError(try document.validate(using: validator)) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: Document contains at least one path")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, ["paths"])
        }
    }

    func test_onePathOnDocumentSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello/world": .init()
            ],
            components: .noComponents
        )

        let validator = Validator.blank.validating(.documentContainsPaths)
        try document.validate(using: validator)
    }

    func test_noOperationsOnPathItemFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello/world": .init()
            ],
            components: .noComponents
        )

        let validator = Validator.blank.validating(.pathsContainOperations)

        XCTAssertThrowsError(try document.validate(using: validator)) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: Paths contain at least one operation")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, ["paths", "/hello/world"])
        }
    }

    func test_oneOperationOnPathItemSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello/world": .init(
                    get: .init(responses: [:])
                )
            ],
            components: .noComponents
        )

        let validator = Validator.blank.validating(.pathsContainOperations)
        try document.validate(using: validator)
    }

    func test_duplicateTagOnDocumentFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [:],
            components: .noComponents,
            tags: ["hello", "hello"]
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: The names of Tags in the Document are unique")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, [])
        }
    }

    func test_uniqueTagsOnDocumentSocceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [:],
            components: .noComponents,
            tags: ["hello", "world"]
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_noResponsesOnOperationFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello/world": .init(
                    get: .init(responses: [:])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: Operations contain at least one response")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, ["paths", "/hello/world", "get", "responses"])
        }
    }

    func test_oneResponseOnOperationSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello/world": .init(
                    get: .init(responses: [
                        200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_duplicateOperationParameterFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(
                        parameters: [
                            .parameter(name: "hiya", context: .path, schema: .string),
                            .parameter(name: "hiya", context: .path, schema: .string)
                        ],
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: Operation parameters are unqiue (identity is defined by the 'name' and 'location')")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, ["paths", "/hello", "get"])
            XCTAssertEqual(error?.values.first?.codingPathString, ".paths['/hello'].get")
        }
    }

    func test_uniqueOperationParametersSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(
                        parameters: [
                            .parameter(name: "hiya", context: .query, schema: .string),
                            .parameter(name: "hiya", context: .path, schema: .string), // changes parameter location but not name
                            .parameter(name: "cool", context: .path, schema: .string)  // changes parameter name but not location
                        ],
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_noOperationParametersSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(
                        parameters: [],
                        responses: [
                            200: .response(description: "hi")
                    ])
                ),
                "/hello/world": .init(
                    put: .init(
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_duplicateOperationIdFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(operationId: "test", responses: [
                        200: .response(description: "hi")
                    ])
                ),
                "/hello/world": .init(
                    put: .init(operationId: "test", responses: [
                        200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: All Operation Ids in Document are unique")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, [])
        }
    }

    func test_uniqueOperationIdsSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(operationId: "one", responses: [
                        200: .response(description: "hi")
                    ])
                ),
                "/hello/world": .init(
                    put: .init(operationId: "two", responses: [
                        200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_noOperationIdsSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(operationId: nil, responses: [
                        200: .response(description: "hi")
                    ])
                ),
                "/hello/world": .init(
                    put: .init(operationId: nil, responses: [
                        200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_duplicatePathItemParameterFails() {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    parameters: [
                        .parameter(name: "hiya", context: .query, schema: .string),
                        .parameter(name: "hiya", context: .query, schema: .string)
                    ],
                    get: .init(
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.first?.reason, "Failed to satisfy: Path Item parameters are unqiue (identity is defined by the 'name' and 'location')")
            XCTAssertEqual(error?.values.first?.codingPath.map { $0.stringValue }, ["paths", "/hello"])
            XCTAssertEqual(error?.values.first?.codingPathString, ".paths['/hello']")
        }
    }

    func test_uniquePathItemParametersSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    parameters: [
                        .parameter(name: "hiya", context: .query, schema: .string),
                        .parameter(name: "hiya", context: .path, schema: .string), // changes parameter location but not name
                        .parameter(name: "cool", context: .path, schema: .string) // changes parameter name but not location
                    ],
                    get: .init(
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_noPathItemParametersSucceeds() throws {
        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": .init(
                    get: .init(
                        parameters: [],
                        responses: [
                            200: .response(description: "hi")
                    ])
                ),
                "/hello/world": .init(
                    put: .init(
                        responses: [
                            200: .response(description: "hi")
                    ])
                )
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        try document.validate()
    }

    func test_oneOfEachReferenceTypeFails() throws {

        let path = OpenAPI.PathItem(
            get: .init(
                parameters: [
                    .reference(.component(named: "parameter1"))
                ],
                requestBody: .reference(.component(named: "request1")),
                responses: [
                    200: .reference(.component(named: "response1")),
                    404: .response(
                        description: "response2",
                        headers: ["header1": .reference(.component(named: "header1"))],
                        content: [
                            .json: .init(
                                schema: .string,
                                examples: [
                                    "example1": .reference(.component(named: "example1"))
                                ]
                            ),
                            .xml: .init(schemaReference: .component(named: "schema1"))
                        ]
                    )
                ]
            )
        )

        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": path
            ],
            components: .noComponents
        )

        // NOTE this is part of default validation
        XCTAssertThrowsError(try document.validate()) { error in
            let error = error as? ValidationErrorCollection
            XCTAssertEqual(error?.values.count, 6)
            XCTAssertEqual(error?.values[0].reason, "Failed to satisfy: Parameter reference can be found in components/parameters")
            XCTAssertEqual(error?.values[0].codingPathString, ".paths['/hello'].get.parameters[0]")
            XCTAssertEqual(error?.values[1].reason, "Failed to satisfy: Request reference can be found in components/requestBodies")
            XCTAssertEqual(error?.values[1].codingPathString, ".paths['/hello'].get.requestBody")
            XCTAssertEqual(error?.values[2].reason, "Failed to satisfy: Response reference can be found in components/responses")
            XCTAssertEqual(error?.values[2].codingPathString, ".paths['/hello'].get.responses.200")
            XCTAssertEqual(error?.values[3].reason, "Failed to satisfy: Header reference can be found in components/headers")
            XCTAssertEqual(error?.values[3].codingPathString, ".paths['/hello'].get.responses.404.headers.header1")
            XCTAssertEqual(error?.values[4].reason, "Failed to satisfy: Example reference can be found in components/examples")
            XCTAssertEqual(error?.values[4].codingPathString, ".paths['/hello'].get.responses.404.content['application/json'].examples.example1")
            XCTAssertEqual(error?.values[5].reason, "Failed to satisfy: JSONSchema reference can be found in components/schemas")
            XCTAssertEqual(error?.values[5].codingPathString, ".paths['/hello'].get.responses.404.content['application/xml'].schema")
        }
    }

    func test_oneOfEachReferenceTypeSucceeds() throws {
        let path = OpenAPI.PathItem(
            put: .init(
                requestBody: .reference(.external(URL(string: "https://website.com/file.json#/hello/world")!)),
                responses: [
                    200: .response(description: "empty")
                ]
            ),
            post: .init(
                parameters: [
                    .reference(.component(named: "parameter1")),
                    .reference(.external(URL(string: "https://website.com/file.json#/hello/world")!))
                ],
                requestBody: .reference(.component(named: "request1")),
                responses: [
                    200: .reference(.component(named: "response1")),
                    301: .reference(.external(URL(string: "https://website.com/file.json#/hello/world")!)),
                    404: .response(
                        description: "response2",
                        headers: [
                            "header1": .reference(.component(named: "header1")),
                            "external": .reference(.external(URL(string: "https://website.com/file.json#/hello/world")!))
                        ],
                        content: [
                            .json: .init(
                                schema: .string,
                                examples: [
                                    "example1": .reference(.component(named: "example1")),
                                    "external": .reference(.external(URL(string: "https://website.com/file.json#/hello/world")!))
                                ]
                            ),
                            .xml: .init(schemaReference: .component(named: "schema1")),
                            .txt: .init(schemaReference: .external(URL(string: "https://website.com/file.json#/hello/world")!))
                        ]
                    )
                ]
            )
        )

        let document = OpenAPI.Document(
            info: .init(title: "test", version: "1.0"),
            servers: [],
            paths: [
                "/hello": path
            ],
            components: .init(
                schemas: [
                    "schema1": .object
                ],
                responses: [
                    "response1": .init(description: "test")
                ],
                parameters: [
                    "parameter1": .init(name: "test", context: .header, schema: .string)
                ],
                examples: [
                    "example1": .init(value: .b("hello"))
                ],
                requestBodies: [
                    "request1": .init(content: [.json: .init(schema: .object)])
                ],
                headers: [
                    "header1": .init(schema: .string)
                ]
            )
        )

        // NOTE this is part of default validation
        try document.validate()
    }
}
