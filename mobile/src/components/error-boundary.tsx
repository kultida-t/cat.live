import { Component, type ErrorInfo, type ReactNode } from 'react';
import { Pressable, Text, View } from 'react-native';

type Props = { children: ReactNode };
type State = { hasError: boolean };

/**
 * ดัก crash ระดับหน้าจอ — จอใดจอหนึ่งพังไม่ให้ลากทั้งแอปดับ
 * ครอบไว้ที่ root layout เพื่อให้ทุก route ได้รับผล
 */
export class ScreenErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('[ScreenErrorBoundary]', error, info.componentStack);
  }

  private reset = () => this.setState({ hasError: false });

  render() {
    if (!this.state.hasError) return this.props.children;
    return (
      <View className="flex-1 items-center justify-center bg-page p-6">
        <Text className="text-5xl">😿</Text>
        <Text className="mt-4 text-xl font-bold text-ink">หน้าจอนี้มีปัญหา</Text>
        <Text className="mt-2 text-center text-base text-ink-muted">
          เกิดข้อผิดพลาดที่ไม่คาดคิด ลองเปิดหน้านี้ใหม่อีกครั้ง
        </Text>
        <Pressable
          onPress={this.reset}
          className="mt-6 rounded-xl border border-btn-border bg-btn px-8 py-3 active:opacity-80">
          <Text className="text-base font-bold text-ink-accent">ลองใหม่</Text>
        </Pressable>
      </View>
    );
  }
}
