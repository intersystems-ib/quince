"""Offline checks for reconstruction of participation from FER match sheets."""
import unittest
from refresh_spanish_match_evidence import minutes_played, normalized, repair_text

class ParticipationTests(unittest.TestCase):
    def test_regular_substitutions_and_unused_bench(self):
        minutes, appeared = minutes_played(list(range(1, 24)), [(3, 16, 41), (9, 21, 60)], {})
        self.assertEqual((minutes[3], minutes[16], minutes[9], minutes[21]), (41, 39, 60, 20))
        self.assertEqual(minutes[23], 0)
        self.assertNotIn(23, appeared)

    def test_temporary_front_row_replacement_and_cards(self):
        minutes, _ = minutes_played(list(range(1, 24)), [(14, 18, 16), (18, 14, 27), (3, 18, 45)], {3: [(16, 10)], 15: [(17, 10)]})
        self.assertEqual((minutes[14], minutes[18], minutes[3], minutes[15]), (69, 46, 35, 70))
        self.assertEqual(sum(minutes.values()), 1180)

    def test_self_replacement_is_unknown_instead_of_invented_minutes(self):
        minutes, _ = minutes_played(list(range(1, 24)), [(21, 21, 56)], {})
        self.assertIsNone(minutes[21])
        self.assertEqual(minutes[1], 80)

    def test_red_card_and_overlapping_sin_bins(self):
        minutes, _ = minutes_played(list(range(1, 24)), [], {5: [(30, 80)], 6: [(10, 10), (15, 10)]})
        self.assertEqual((minutes[5], minutes[6]), (30, 65))

    def test_repairs_encoding_without_fuzzy_identity_matching(self):
        self.assertEqual(repair_text('COMESA\u00c3\u0091A'), 'COMESAÑA')
        self.assertEqual(repair_text('MAR\u00c3\u0083\u00e2\u0080\u00a1AL'), 'MARÇAL')
        self.assertEqual(normalized('PEREZ MERO\u00c3\u0091O'), normalized('Pérez Meroño'))

    def test_names_match_without_inventing_identity(self):
        self.assertEqual(normalized('Manuel Sainz-Trápaga'), normalized('MANUEL SAINZ TRAPAGA'))
        self.assertNotEqual(normalized('Ike Irusta Salles'), normalized('Yako Irusta Salles'))

if __name__ == '__main__': unittest.main()
