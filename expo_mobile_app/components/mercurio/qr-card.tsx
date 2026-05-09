import Svg, { Rect } from "react-native-svg";

function bitFor(seed: string, row: number, col: number) {
  const char = seed.charCodeAt((row * 7 + col * 11) % seed.length) || 77;
  return (char + row * 3 + col * 5) % 3 !== 0;
}

export function QrCard({ value, size = 190 }: { value: string; size?: number }) {
  const cells = 13;
  const gap = 3;
  const cell = (size - gap * (cells + 1)) / cells;
  const finder = [
    [0, 0],
    [0, cells - 3],
    [cells - 3, 0],
  ];

  return (
    <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <Rect x={0} y={0} width={size} height={size} rx={24} fill="#FFFFFF" />
      {finder.map(([row, col]) => (
        <Rect
          key={`${row}-${col}`}
          x={gap + col * (cell + gap)}
          y={gap + row * (cell + gap)}
          width={cell * 3 + gap * 2}
          height={cell * 3 + gap * 2}
          rx={8}
          fill="#243B8F"
        />
      ))}
      {Array.from({ length: cells }).flatMap((_, row) =>
        Array.from({ length: cells }).map((__, col) => {
          const inFinder = finder.some(([fr, fc]) => row >= fr && row < fr + 3 && col >= fc && col < fc + 3);
          if (inFinder || !bitFor(value, row, col)) return null;
          return (
            <Rect
              key={`${row}-${col}`}
              x={gap + col * (cell + gap)}
              y={gap + row * (cell + gap)}
              width={cell}
              height={cell}
              rx={cell / 3}
              fill={row % 2 === 0 ? "#22D3EE" : "#243B8F"}
            />
          );
        }),
      )}
    </Svg>
  );
}
