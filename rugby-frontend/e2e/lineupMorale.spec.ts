import { test, expect } from '@playwright/test';
import { lineupMorale, positionPenalty } from '../src/lineupAvailability';
import type { Player } from '../src/types';

test('every position within the same unit preserves the displayed morale', () => {
    for (let natural = 1; natural <= 15; natural++) {
        const player = { position: natural, secondary: [], morale: 73 } as unknown as Player;
        for (let position = 1; position <= 15; position++) {
            const sameGroup = (natural <= 8) === (position <= 8);
            expect(positionPenalty(player, position)).toBe(sameGroup ? 0 : 15);
            expect(lineupMorale(player, position)).toBe(sameGroup ? 73 : 58);
        }
        expect(player.morale).toBe(73);
        expect(lineupMorale(player)).toBe(73);
    }
});

test('secondary positions in the same unit are free and cross-unit rules remain consistent', () => {
    const player = { position: 1, secondary: [2, 9], morale: 73 } as unknown as Player;
    expect(lineupMorale(player, 2)).toBe(73);
    expect(lineupMorale(player, 8)).toBe(73);
    expect(lineupMorale(player, 9)).toBe(70);
    expect(lineupMorale(player, 15)).toBe(58);
    expect(player.morale).toBe(73);
});
