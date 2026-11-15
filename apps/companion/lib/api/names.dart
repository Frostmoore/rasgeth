// The RedGiant's name as people read it (G40.8). The server says the machine's name (the one the
// nodes show: the person's, set in Settings or here, else the host's); in a container or a VM
// the host's is a generated id («350003b5f4e6»), which nobody reads as a name. One pure rule,
// tested as a table.

/// A host name made by a machine, not given by a person: a container's id, a VM's default.
bool looksGenerated(String name) {
  final n = name.trim().toLowerCase();
  return n.isEmpty ||
      n == 'localhost' ||
      // Docker and Podman: the first 12 characters of the id (or all 64).
      RegExp(r'^[0-9a-f]{12}$').hasMatch(n) ||
      RegExp(r'^[0-9a-f]{64}$').hasMatch(n) ||
      // A random hex id of another length that has digits and letters both.
      (RegExp(r'^[0-9a-f]{8,}$').hasMatch(n) &&
          RegExp(r'\d').hasMatch(n) &&
          RegExp(r'[a-f]').hasMatch(n));
}

/// The name to show: the person's own in the app ([label]) when it is one, else the server's
/// ([machine]) when it is one, else «RedGiant». The OS's own host name reads as the product.
String readableName({String? label, String? machine}) {
  String? usable(String? s) {
    final t = s?.trim() ?? '';
    if (looksGenerated(t)) return null;
    return t.toLowerCase() == 'redgiant' ? 'RedGiant' : t;
  }

  return usable(label) ?? usable(machine) ?? 'RedGiant';
}
