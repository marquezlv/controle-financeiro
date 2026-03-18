import 'package:flutter/material.dart';

class SuspenseMenuButton extends StatelessWidget {
	final VoidCallback onPressed;

	const SuspenseMenuButton({
		super.key,
		required this.onPressed,
	});

	@override
	Widget build(BuildContext context) {
		return SafeArea(
			child: Padding(
				padding: const EdgeInsets.only(right: 12, top: 8),
				child: Material(
					color: Colors.transparent,
					child: Ink(
						width: 42,
						height: 42,
						decoration: BoxDecoration(
							color: Colors.white.withAlpha((0.9 * 255).round()),
							shape: BoxShape.circle,
							boxShadow: [
								BoxShadow(
									color: Colors.black.withAlpha((0.12 * 255).round()),
									blurRadius: 12,
									offset: const Offset(0, 3),
								),
							],
						),
						child: IconButton(
							icon: const Icon(Icons.menu_rounded),
							color: const Color(0xFF1E4ED8),
							splashRadius: 22,
							onPressed: onPressed,
						),
					),
				),
			),
		);
	}
}

class SuspenseMenuDrawer extends StatelessWidget {
	final int selectedIndex;
	final ValueChanged<int> onNavigate;

	const SuspenseMenuDrawer({
		super.key,
		required this.selectedIndex,
		required this.onNavigate,
	});

	@override
	Widget build(BuildContext context) {
		return Drawer(
			child: SafeArea(
				child: Column(
					children: [
						Container(
							width: double.infinity,
							padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
							decoration: const BoxDecoration(
								gradient: LinearGradient(
									colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
								),
							),
							child: const Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'Menu',
										style: TextStyle(
											color: Colors.white,
											fontSize: 22,
											fontWeight: FontWeight.bold,
										),
									),
									SizedBox(height: 6),
									Text(
										'Navegue entre funcionalidades',
										style: TextStyle(color: Colors.white70),
									),
								],
							),
						),
						Expanded(
							child: ListView(
								padding: const EdgeInsets.symmetric(vertical: 8),
								children: [
									_menuItem(
										context,
										icon: Icons.home_rounded,
										label: 'Início',
										index: 0,
									),
									_menuItem(
										context,
										icon: Icons.trending_down_rounded,
										label: 'Gastos',
										index: 1,
									),
									_menuItem(
										context,
										icon: Icons.trending_up_rounded,
										label: 'Ganhos',
										index: 2,
									),
									_menuItem(
										context,
										icon: Icons.folder_rounded,
										label: 'Projeções',
										index: 3,
									),
									const Divider(height: 24),
									const ListTile(
										leading: Icon(Icons.auto_awesome_outlined),
										title: Text('Novas funcionalidades em breve'),
										subtitle: Text('Este menu está pronto para expansão'),
									),
								],
							),
						),
					],
				),
			),
		);
	}

	Widget _menuItem(
		BuildContext context, {
		required IconData icon,
		required String label,
		required int index,
	}) {
		final selected = index == selectedIndex;
		return ListTile(
			leading: Icon(
				icon,
				color: selected ? const Color(0xFF2F6BFF) : null,
			),
			title: Text(
				label,
				style: TextStyle(
					fontWeight: selected ? FontWeight.bold : FontWeight.w500,
					color: selected ? const Color(0xFF2F6BFF) : null,
				),
			),
			selected: selected,
			onTap: () {
				Navigator.of(context).pop();
				onNavigate(index);
			},
		);
	}
}
