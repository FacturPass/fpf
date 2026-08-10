// netstandard2.0 predates C# 9 records/init accessors at the BCL level —
// the compiler needs this marker type to exist somewhere in the compiled
// output. Standard, widely-used community workaround (the same trick the
// PolySharp NuGet package automates) rather than pulling in an extra
// dependency for a single empty marker type.
namespace System.Runtime.CompilerServices
{
    internal static class IsExternalInit { }
}
