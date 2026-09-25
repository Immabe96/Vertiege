import { fireEvent, render, screen } from '@testing-library/react-native';
import * as React from 'react';

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Avatar, AvatarBadge, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ButtonGroup, ButtonGroupText } from '@/components/ui/button-group';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { DropdownMenu } from '@/components/ui/dropdown-menu';
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from '@/components/ui/empty';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Progress } from '@/components/ui/progress';
import { Select } from '@/components/ui/select';
import { Separator } from '@/components/ui/separator';
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet';
import { Skeleton } from '@/components/ui/skeleton';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Text } from '@/components/ui/text';
import { Textarea } from '@/components/ui/textarea';
import { ToastProvider, useToast } from '@/components/ui/toast';
import { Tooltip } from '@/components/ui/tooltip';

describe('Button', () => {
  test('renders its label and fires onPress', async () => {
    const onPress = jest.fn();
    await render(<Button onPress={onPress}>Sign in</Button>);

    const button = screen.getByRole('button');
    expect(button).toBeTruthy();
    expect(screen.getByText('Sign in')).toBeTruthy();

    await fireEvent.press(button);
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  test('exposes the disabled state and blocks presses', async () => {
    const onPress = jest.fn();
    await render(
      <Button disabled onPress={onPress}>
        Disabled
      </Button>
    );

    expect(screen.getByRole('button').props.accessibilityState.disabled).toBe(true);
    await fireEvent.press(screen.getByRole('button'));
    expect(onPress).not.toHaveBeenCalled();
  });

  test('renders composed children without re-wrapping them', async () => {
    await render(
      <Button>
        <Text>Continue</Text>
      </Button>
    );
    expect(screen.getByText('Continue')).toBeTruthy();
  });
});

describe('ButtonGroup', () => {
  test('renders every child in order', async () => {
    await render(
      <ButtonGroup>
        <Button>Day</Button>
        <Button>Week</Button>
        <Button>Month</Button>
      </ButtonGroup>
    );
    expect(screen.getByText('Day')).toBeTruthy();
    expect(screen.getByText('Week')).toBeTruthy();
    expect(screen.getByText('Month')).toBeTruthy();
  });

  test('label slot renders its text', async () => {
    await render(
      <ButtonGroup>
        <ButtonGroupText>Label</ButtonGroupText>
        <Button>Go</Button>
      </ButtonGroup>
    );
    expect(screen.getByText('Label')).toBeTruthy();
  });
});

describe('Checkbox', () => {
  test('reports its checked state and toggles', async () => {
    const onCheckedChange = jest.fn();
    await render(<Checkbox checked={false} onCheckedChange={onCheckedChange} />);

    const checkbox = screen.getByRole('checkbox');
    expect(checkbox.props.accessibilityState.checked).toBe(false);

    await fireEvent.press(checkbox);
    expect(onCheckedChange).toHaveBeenCalledWith(true);
  });

  test('indeterminate reports as mixed', async () => {
    await render(<Checkbox indeterminate checked={false} />);
    expect(screen.getByRole('checkbox').props.accessibilityState.checked).toBe('mixed');
  });

  test('disabled state is exposed and blocks presses', async () => {
    const onCheckedChange = jest.fn();
    await render(<Checkbox checked disabled onCheckedChange={onCheckedChange} />);

    const checkbox = screen.getByRole('checkbox');
    expect(checkbox.props.accessibilityState.disabled).toBe(true);
    await fireEvent.press(checkbox);
    expect(onCheckedChange).not.toHaveBeenCalled();
  });
});

describe('Switch', () => {
  test('exposes on/off and toggles', async () => {
    const onCheckedChange = jest.fn();
    await render(<Switch checked onCheckedChange={onCheckedChange} />);

    const control = screen.getByRole('switch');
    expect(control.props.accessibilityState.checked).toBe(true);

    await fireEvent.press(control);
    expect(onCheckedChange).toHaveBeenCalledWith(false);
  });

  test('disabled state is exposed', async () => {
    await render(<Switch checked={false} disabled />);
    expect(screen.getByRole('switch').props.accessibilityState.disabled).toBe(true);
  });
});

describe('Input and Textarea', () => {
  test('input forwards accessibility label and editing', async () => {
    const onChangeText = jest.fn();
    await render(<Input accessibilityLabel="Email" value="a@b.c" onChangeText={onChangeText} />);

    expect(screen.getByLabelText('Email')).toBeTruthy();
    await fireEvent.changeText(screen.getByLabelText('Email'), 'x');
    expect(onChangeText).toHaveBeenCalledWith('x');
  });

  test('disabled input is not editable', async () => {
    await render(<Input accessibilityLabel="Locked" editable={false} />);
    expect(screen.getByLabelText('Locked').props.editable).toBe(false);
  });

  test('textarea is a multiline field', async () => {
    await render(<Textarea accessibilityLabel="Message" />);
    expect(screen.getByLabelText('Message').props.multiline).toBe(true);
  });

  test('label renders its children', async () => {
    await render(<Label>Email</Label>);
    expect(screen.getByText('Email')).toBeTruthy();
  });
});

describe('Badge', () => {
  test.each(['default', 'neutral', 'main', 'secondary', 'success', 'warning', 'danger'] as const)(
    'renders the %s variant',
    async (variant) => {
      await render(<Badge variant={variant}>Tier</Badge>);
      expect(screen.getByText('Tier')).toBeTruthy();
    }
  );

  test('keeps a single line (upstream whitespace-nowrap)', async () => {
    await render(<Badge>Long badge label</Badge>);
    expect(screen.getByText('Long badge label').props.numberOfLines).toBe(1);
  });
});

describe('Card', () => {
  test('composes header, content and footer', async () => {
    await render(
      <Card>
        <CardHeader>
          <CardTitle>Card title</CardTitle>
          <CardDescription>
            <Text>Supporting line</Text>
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Text>Body</Text>
        </CardContent>
        <CardFooter>
          <Button>Action</Button>
        </CardFooter>
      </Card>
    );

    expect(screen.getByText('Card title')).toBeTruthy();
    expect(screen.getByText('Supporting line')).toBeTruthy();
    expect(screen.getByText('Body')).toBeTruthy();
    expect(screen.getByRole('button')).toBeTruthy();
  });

  test('small size renders', async () => {
    await render(
      <Card size="sm">
        <CardContent>
          <Text>Compact</Text>
        </CardContent>
      </Card>
    );
    expect(screen.getByText('Compact')).toBeTruthy();
  });
});

describe('Avatar', () => {
  test('shows initials when there is no image', async () => {
    await render(<Avatar fallback="RS" />);
    expect(screen.getByText('RS')).toBeTruthy();
  });

  test('exposes an avatar accessibility label', async () => {
    await render(<Avatar fallback="RS" />);
    expect(screen.getByLabelText('Avatar RS')).toBeTruthy();
  });

  test('badge overlay renders', async () => {
    await render(
      <Avatar fallback="RS">
        <AvatarBadge />
      </Avatar>
    );
    expect(screen.getByLabelText('Online')).toBeTruthy();
  });

  test('fallback component renders text', async () => {
    await render(<AvatarFallback>VK</AvatarFallback>);
    expect(screen.getByText('VK')).toBeTruthy();
  });
});

describe('Tabs', () => {
  const tabs = (
    <Tabs defaultValue="one">
      <TabsList>
        <TabsTrigger value="one">One</TabsTrigger>
        <TabsTrigger value="two">Two</TabsTrigger>
      </TabsList>
      <TabsContent value="one">
        <Text>First panel</Text>
      </TabsContent>
      <TabsContent value="two">
        <Text>Second panel</Text>
      </TabsContent>
    </Tabs>
  );

  test('marks the active trigger as selected', async () => {
    await render(tabs);
    const triggers = screen.getAllByRole('tab');
    expect(triggers[0].props.accessibilityState.selected).toBe(true);
    expect(triggers[1].props.accessibilityState.selected).toBe(false);
  });

  test('switching trigger swaps the visible panel', async () => {
    await render(tabs);
    expect(screen.getByText('First panel')).toBeTruthy();

    await fireEvent.press(screen.getByRole('tab', { name: 'Two' }));
    expect(screen.getByText('Second panel')).toBeTruthy();
    expect(screen.queryByText('First panel')).toBeNull();
  });

  test('disabled trigger is exposed', async () => {
    await render(
      <Tabs defaultValue="one">
        <TabsList>
          <TabsTrigger value="one">One</TabsTrigger>
          <TabsTrigger value="two" disabled>
            Two
          </TabsTrigger>
        </TabsList>
      </Tabs>
    );
    expect(screen.getByRole('tab', { name: 'Two' }).props.accessibilityState.disabled).toBe(true);
  });
});

describe('Progress', () => {
  test('exposes the progressbar role', async () => {
    await render(<Progress value={40} label="XP" valueText="40/100" />);
    expect(screen.getByRole('progressbar')).toBeTruthy();
    expect(screen.getByText('XP')).toBeTruthy();
    expect(screen.getByText('40/100')).toBeTruthy();
  });
});

describe('Skeleton, Separator, Empty', () => {
  test('skeleton renders', async () => {
    await render(<Skeleton />);
    expect(screen.toJSON()).toBeTruthy();
  });

  test('separator renders both orientations', async () => {
    const { rerender } = await render(<Separator />);
    expect(screen.toJSON()).toBeTruthy();
    await rerender(<Separator orientation="vertical" />);
    expect(screen.toJSON()).toBeTruthy();
  });

  test('empty state renders title, description and action', async () => {
    await render(
      <Empty>
        <EmptyHeader>
          <EmptyTitle>Nothing here yet</EmptyTitle>
          <EmptyDescription>Posts will land here.</EmptyDescription>
        </EmptyHeader>
        <EmptyContent>
          <Button size="sm">Browse worlds</Button>
        </EmptyContent>
      </Empty>
    );

    expect(screen.getByText('Nothing here yet')).toBeTruthy();
    expect(screen.getByText('Posts will land here.')).toBeTruthy();
    expect(screen.getByRole('button')).toBeTruthy();
  });
});

describe('Dialog', () => {
  const dialog = (onOpenChange = jest.fn()) => (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Leave this world?</DialogTitle>
          <DialogDescription>Your residents will notice.</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button size="sm">Stay</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );

  test('renders content while open and hides it when closed', async () => {
    const { rerender } = await render(dialog());
    expect(screen.getByText('Leave this world?')).toBeTruthy();

    await rerender(<Dialog open={false} onOpenChange={jest.fn()} />);
    expect(screen.queryByText('Leave this world?')).toBeNull();
  });

  test('scrim press requests close', async () => {
    const onOpenChange = jest.fn();
    await render(dialog(onOpenChange));

    await fireEvent.press(screen.getByLabelText('Close dialog'));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  test('close button requests close', async () => {
    const onOpenChange = jest.fn();
    await render(dialog(onOpenChange));

    await fireEvent.press(screen.getByLabelText('Close'));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });

  test('close button can be hidden', async () => {
    await render(
      <Dialog open onOpenChange={jest.fn()} showCloseButton={false}>
        <DialogContent>
          <DialogTitle>No ×</DialogTitle>
        </DialogContent>
      </Dialog>
    );
    expect(screen.queryByLabelText('Close')).toBeNull();
  });
});

describe('AlertDialog', () => {
  test('content carries the alert role and actions render', async () => {
    await render(
      <AlertDialog open onOpenChange={jest.fn()}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete message?</AlertDialogTitle>
            <AlertDialogDescription>This cannot be undone.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction>Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    );

    expect(screen.getByRole('alert')).toBeTruthy();
    expect(screen.getByText('Delete message?')).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Delete' })).toBeTruthy();
  });
});

describe('Sheet', () => {
  test('renders header, title and description while open', async () => {
    await render(
      <Sheet open onOpenChange={jest.fn()} side="bottom">
        <SheetContent>
          <SheetHeader>
            <SheetTitle>Switch world</SheetTitle>
            <SheetDescription>Pick where you are posting from.</SheetDescription>
          </SheetHeader>
        </SheetContent>
      </Sheet>
    );

    expect(screen.getByText('Switch world')).toBeTruthy();
    expect(screen.getByText('Pick where you are posting from.')).toBeTruthy();
  });

  test('close button requests close', async () => {
    const onOpenChange = jest.fn();
    await render(
      <Sheet open onOpenChange={onOpenChange}>
        <SheetContent>
          <SheetTitle>Title</SheetTitle>
        </SheetContent>
      </Sheet>
    );

    await fireEvent.press(screen.getByLabelText('Close'));
    expect(onOpenChange).toHaveBeenCalledWith(false);
  });
});

describe('Select', () => {
  const options = [
    { value: 'campfire', label: 'Campfire' },
    { value: 'nexus', label: 'Nexus' },
  ];

  test('trigger exposes the selected label and opens the option list', async () => {
    await render(<Select value="nexus" options={options} accessibilityLabel="World" />);

    const trigger = screen.getByLabelText('World');
    expect(trigger.props.accessibilityState.expanded).toBe(false);
    expect(screen.queryByText('Campfire')).toBeNull();

    await fireEvent.press(trigger);
    expect(screen.getByText('Campfire')).toBeTruthy();
  });

  test('selecting an option reports the value and closes', async () => {
    const onValueChange = jest.fn();
    await render(
      <Select
        value="campfire"
        options={options}
        accessibilityLabel="World"
        onValueChange={onValueChange}
      />
    );

    await fireEvent.press(screen.getByLabelText('World'));
    await fireEvent.press(screen.getByRole('menuitem', { name: 'Nexus' }));
    expect(onValueChange).toHaveBeenCalledWith('nexus');
    expect(screen.queryByRole('menuitem', { name: 'Nexus' })).toBeNull();
  });

  test('disabled trigger does not open', async () => {
    await render(<Select disabled value="campfire" options={options} accessibilityLabel="World" />);
    await fireEvent.press(screen.getByLabelText('World'));
    expect(screen.queryByText('Nexus')).toBeNull();
  });
});

describe('DropdownMenu', () => {
  test('opens from the cloned trigger and runs the chosen item', async () => {
    const onPress = jest.fn();
    await render(
      <DropdownMenu
        title="Post actions"
        items={[{ value: 'bookmark', label: 'Bookmark', onPress }]}
        trigger={<Button size="sm">Menu</Button>}
      />
    );

    expect(screen.queryByText('Bookmark')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Menu' }));
    expect(screen.getByRole('menu')).toBeTruthy();

    await fireEvent.press(screen.getByRole('menuitem', { name: 'Bookmark' }));
    expect(onPress).toHaveBeenCalledTimes(1);
  });
});

describe('Toast', () => {
  function Harness() {
    const { toast } = useToast();
    return (
      <Button onPress={() => toast({ title: 'Posted to the Nexus', description: 'Nice.' })}>
        Fire
      </Button>
    );
  }

  test('renders a toast with its title and description', async () => {
    await render(
      <ToastProvider>
        <Harness />
      </ToastProvider>
    );

    await fireEvent.press(screen.getByRole('button'));
    expect(screen.getByText('Posted to the Nexus')).toBeTruthy();
    expect(screen.getByText('Nice.')).toBeTruthy();
  });

  test('tap dismisses it', async () => {
    await render(
      <ToastProvider>
        <Harness />
      </ToastProvider>
    );

    await fireEvent.press(screen.getByRole('button'));
    await fireEvent.press(screen.getByLabelText(/Dismiss: Posted to the Nexus/));
    expect(screen.queryByText('Posted to the Nexus')).toBeNull();
  });
});

describe('Tooltip', () => {
  test('long-press reveals the hint', async () => {
    await render(
      <Tooltip content="What is a tier?">
        <Badge>?</Badge>
      </Tooltip>
    );

    expect(screen.queryByText('What is a tier?')).toBeNull();
    await fireEvent(screen.getByText('?'), 'longPress');
    expect(screen.getByText('What is a tier?')).toBeTruthy();
  });
});
