import Svg, {
  Circle,
  Defs,
  Ellipse,
  G,
  LinearGradient,
  Path,
  Rect,
  Stop,
} from 'react-native-svg';

export type NavIconName = 'home' | 'feed' | 'nearby' | 'ai' | 'help' | 'mycat';

type Props = { name: NavIconName; active: boolean; size?: number };

const GRADIENT = {
  off: { from: '#CDBFB0', to: '#9C8A79' },
  on: { from: '#9A7760', to: '#4A3428' },
} as const;

const HIGHLIGHT = 'rgba(255,255,255,0.45)';

/** ไอคอนแท็บล่างแบบ gradient — วาดตาม SVG ของเว็บ prototype ทุกตัว */
export function NavIcon({ name, active, size = 30 }: Props) {
  const g = active ? GRADIENT.on : GRADIENT.off;
  const id = `nav-${name}-${active ? 'on' : 'off'}`;
  const fill = `url(#${id})`;

  return (
    <Svg width={size} height={size} viewBox="0 0 32 32">
      <Defs>
        <LinearGradient id={id} x1="0" y1="0" x2="0" y2="1">
          <Stop offset="0" stopColor={g.from} />
          <Stop offset="1" stopColor={g.to} />
        </LinearGradient>
      </Defs>
      {name === 'home' && (
        <>
          <Path d="M4 15.2 16 4.5l12 10.7V27a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2Z" fill={fill} />
          <Path
            d="M7 14.5 16 6.6l6 5.3"
            fill="none"
            stroke={HIGHLIGHT}
            strokeWidth={1.8}
            strokeLinecap="round"
          />
          <Rect x={13} y={19} width={6} height={10} rx={1.5} fill="#fff" opacity={0.75} />
        </>
      )}
      {name === 'feed' &&
        [
          [4, 4],
          [17, 4],
          [4, 17],
          [17, 17],
        ].map(([x, y]) => (
          <G key={`${x}-${y}`}>
            <Rect x={x} y={y} width={11} height={11} rx={3.2} fill={fill} />
            <Rect x={x + 2} y={y + 1.6} width={5} height={2.2} rx={1.1} fill={HIGHLIGHT} />
          </G>
        ))}
      {name === 'nearby' && (
        <>
          <Path
            d="M16 3c5.8 0 10 4.3 10 9.8C26 20 16 29 16 29S6 20 6 12.8C6 7.3 10.2 3 16 3Z"
            fill={fill}
          />
          <Circle cx={16} cy={12.5} r={4} fill="#fff" opacity={0.8} />
          <Path
            d="M9.5 9.5a7 7 0 0 1 4-4"
            fill="none"
            stroke={HIGHLIGHT}
            strokeWidth={1.8}
            strokeLinecap="round"
          />
        </>
      )}
      {name === 'ai' && (
        <>
          <Path
            d="M16 3.5c7 0 12.5 4.9 12.5 11.1S23 25.7 16 25.7c-1.4 0-2.7-.2-4-.5L5.2 28.5l1.7-5.4C4.8 21.1 3.5 18 3.5 14.6 3.5 8.4 9 3.5 16 3.5Z"
            fill={fill}
          />
          <Path
            d="M8 9.8c1.6-2.5 4.4-4 7.6-4.2"
            fill="none"
            stroke={HIGHLIGHT}
            strokeWidth={1.8}
            strokeLinecap="round"
          />
          <Path
            d="M14.6 8.4C15.656 13.944 15.656 13.944 21.2 15C15.656 16.056 15.656 16.056 14.6 21.6C13.544 16.056 13.544 16.056 8 15C13.544 13.944 13.544 13.944 14.6 8.4Z"
            fill="#fff"
          />
          <Path
            d="M21.4 7.6C21.816 9.784 21.816 9.784 24 10.2C21.816 10.616 21.816 10.616 21.4 12.8C20.984 10.616 20.984 10.616 18.8 10.2C20.984 9.784 20.984 9.784 21.4 7.6Z"
            fill="#fff"
          />
        </>
      )}
      {name === 'help' && (
        <>
          <Path
            d="M16 28S3.5 20.6 3.5 11.9A6.6 6.6 0 0 1 16 8.4a6.6 6.6 0 0 1 12.5 3.5C28.5 20.6 16 28 16 28Z"
            fill={fill}
          />
          <Ellipse
            cx={9.8}
            cy={11}
            rx={2.6}
            ry={1.7}
            transform="rotate(-35 9.8 11)"
            fill={HIGHLIGHT}
          />
        </>
      )}
      {name === 'mycat' && (
        <>
          <Path d="M5 5.5 11 10h10l6-4.5V18c0 6.1-4.9 10.5-11 10.5S5 24.1 5 18Z" fill={fill} />
          <Path
            d="M8 9.5 10.6 11.6M24 9.5l-2.6 2.1"
            stroke={HIGHLIGHT}
            strokeWidth={1.6}
            strokeLinecap="round"
          />
          <Ellipse cx={11.6} cy={17} rx={2.6} ry={3} fill="#fff" />
          <Ellipse cx={20.4} cy={17} rx={2.6} ry={3} fill="#fff" />
          <Circle cx={11.6} cy={17.4} r={1.5} fill="#5E4636" />
          <Circle cx={20.4} cy={17.4} r={1.5} fill="#5E4636" />
          <Circle cx={12.1} cy={16.8} r={0.5} fill="#fff" />
          <Circle cx={20.9} cy={16.8} r={0.5} fill="#fff" />
          <Path d="M14.8 21.6h2.4L16 22.9Z" fill="#F4A3B4" />
        </>
      )}
    </Svg>
  );
}
