import XCTest
@testable import Engines

final class PhysiognomyEngineTests: XCTestCase {
    func test_weighted_score_matches_design_formula() {
        let result = PhysiognomyEngine.analyze(.init(
            eyebrow: 80,
            eye: 70,
            nose: 60,
            mouth: 50,
            ear: 40,
            chin: 30
        ))

        XCTAssertEqual(result.score, 58)
        XCTAssertEqual(result.templateId, "physiognomy.steady")
    }

    func test_template_boundaries() {
        XCTAssertEqual(PhysiognomyEngine.templateId(for: 39), "physiognomy.caution")
        XCTAssertEqual(PhysiognomyEngine.templateId(for: 40), "physiognomy.steady")
        XCTAssertEqual(PhysiognomyEngine.templateId(for: 69), "physiognomy.steady")
        XCTAssertEqual(PhysiognomyEngine.templateId(for: 70), "physiognomy.flourish")
    }

    func test_inputs_are_clamped_to_zero_through_one_hundred() {
        let result = PhysiognomyEngine.analyze(.init(
            eyebrow: 200,
            eye: 200,
            nose: 200,
            mouth: 200,
            ear: 200,
            chin: 200
        ))

        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.templateId, "physiognomy.flourish")
    }
}
