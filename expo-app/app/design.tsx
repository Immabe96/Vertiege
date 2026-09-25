import { Redirect, Stack } from 'expo-router';
import * as React from 'react';
import { ScrollView, View } from 'react-native';
import { Inbox } from 'lucide-react-native';

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
import { Avatar, AvatarBadge } from '@/components/ui/avatar';
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
  EmptyMedia,
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
import { HEX } from '@/lib/theme/tokens';

/**
 * `/design` — every primitive in every documented state, for eyeballing the
 * port against neobrutalism.dev. Dev-only: production redirects to the Nexus.
 */
export default function DesignRoute() {
  if (!__DEV__) return <Redirect href="/" />;

  return (
    <ToastProvider>
      <Stack.Screen options={{ title: 'Design', headerShown: true }} />
      <ScrollView className="flex-1 bg-background" contentContainerClassName="gap-8 p-4 pb-16">
        <Section title="Colour">
          <View className="flex-row flex-wrap gap-2">
            {(
              [
                ['background', 'Ground'],
                ['secondary-background', 'Card'],
                ['background-raised', 'Raised'],
                ['main', 'CTA'],
                ['secondary', 'Link'],
                ['muted', 'Muted'],
                ['success', 'Success'],
                ['warning', 'Warning'],
                ['danger', 'Danger'],
                ['foreground', 'Ink'],
              ] as const
            ).map(([token, label]) => (
              <View key={token} className="w-24 gap-1">
                <View
                  className="h-12 rounded-base border-2 border-border"
                  style={{ backgroundColor: HEX[token] }}
                />
                <Text variant="caption">{label}</Text>
                <Text variant="caption" className="text-muted-foreground">
                  {HEX[token]}
                </Text>
              </View>
            ))}
          </View>
        </Section>

        <Section title="Type">
          <Text variant="display">Display</Text>
          <Text variant="section">Section</Text>
          <Text variant="title">Title</Text>
          <Text variant="body">Body — the default reading weight.</Text>
          <Text variant="small">Small</Text>
          <Text variant="caption">Caption</Text>
          <Text variant="body" tone="secondary">
            Secondary (violet link ink)
          </Text>
          <Text variant="body" tone="muted">
            Muted
          </Text>
          <Text variant="body" tone="success">
            Success ink
          </Text>
          <Text variant="body" tone="warning">
            Warning ink
          </Text>
          <Text variant="body" tone="danger">
            Danger ink
          </Text>
        </Section>

        <Section title="Button">
          <View className="gap-3">
            <View className="flex-row flex-wrap items-center gap-3">
              <Button>Primary</Button>
              <Button variant="neutral">Neutral</Button>
              <Button variant="reverse">Reverse</Button>
              <Button variant="noShadow">No shadow</Button>
            </View>
            <View className="flex-row flex-wrap items-center gap-3">
              <Button size="xs">xs</Button>
              <Button size="sm">sm</Button>
              <Button size="default">default</Button>
              <Button size="lg">lg</Button>
            </View>
            <View className="flex-row flex-wrap items-center gap-3">
              <Button disabled>Disabled</Button>
              <Button variant="neutral" disabled>
                Disabled
              </Button>
              <Button size="icon" accessibilityLabel="Icon">
                ★
              </Button>
            </View>
            <ButtonGroup>
              <Button>Day</Button>
              <Button variant="neutral">Week</Button>
              <Button variant="neutral">Month</Button>
            </ButtonGroup>
            <ButtonGroup orientation="vertical" className="self-start">
              <Button size="sm">One</Button>
              <Button size="sm" variant="neutral">
                Two
              </Button>
            </ButtonGroup>
            <ButtonGroup>
              <ButtonGroupText>Label</ButtonGroupText>
              <Button>Go</Button>
            </ButtonGroup>
          </View>
        </Section>

        <Section title="Inputs">
          <View className="gap-3">
            <View className="gap-1.5">
              <Label>Email</Label>
              <Input placeholder="you@vertiege.app" keyboardType="email-address" />
            </View>
            <Input placeholder="Disabled" editable={false} />
            <Textarea placeholder="Say something to the Nexus…" />
            <SelectDemo />
            <View className="flex-row items-center gap-4">
              <CheckboxDemo />
              <SwitchDemo />
            </View>
            <Tooltip content="Long-press a control to reveal its hint">
              <Badge variant="neutral">Long-press for a tooltip</Badge>
            </Tooltip>
          </View>
        </Section>

        <Section title="Badge">
          <View className="flex-row flex-wrap gap-2">
            <Badge>Default</Badge>
            <Badge variant="neutral">Neutral</Badge>
            <Badge variant="main">Main</Badge>
            <Badge variant="secondary">Secondary</Badge>
            <Badge variant="success">Success</Badge>
            <Badge variant="warning">Warning</Badge>
            <Badge variant="danger">Danger</Badge>
          </View>
        </Section>

        <Section title="Card">
          <Card>
            <CardHeader>
              <CardTitle>Card title</CardTitle>
              <CardDescription>
                <Text variant="small">Description sits under the title.</Text>
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Text variant="body">Card body content with the 24px rhythm.</Text>
            </CardContent>
            <CardFooter>
              <Button size="sm">Action</Button>
            </CardFooter>
          </Card>
          <Card size="sm">
            <CardContent>
              <Text variant="small">Small card — 16px rhythm.</Text>
            </CardContent>
          </Card>
        </Section>

        <Section title="Avatar">
          <View className="flex-row items-center gap-4">
            <Avatar size="sm" fallback="RS" />
            <Avatar size="default" fallback="RS">
              <AvatarBadge />
            </Avatar>
            <Avatar size="lg" fallback="RS" />
            <Avatar
              size="default"
              src={{ uri: 'https://example.invalid/missing.png' }}
              fallback="?"
            />
          </View>
        </Section>

        <Section title="Tabs">
          <Tabs defaultValue="one">
            <TabsList>
              <TabsTrigger value="one">Boxed</TabsTrigger>
              <TabsTrigger value="two">Two</TabsTrigger>
              <TabsTrigger value="three" disabled>
                Off
              </TabsTrigger>
            </TabsList>
            <TabsContent value="one">
              <Text variant="small">Boxed variant — active is `bg-main`.</Text>
            </TabsContent>
            <TabsContent value="two">
              <Text variant="small">Second panel.</Text>
            </TabsContent>
          </Tabs>
          <Tabs defaultValue="a">
            <TabsList variant="line">
              <TabsTrigger value="a">Line</TabsTrigger>
              <TabsTrigger value="b">Two</TabsTrigger>
            </TabsList>
            <TabsContent value="a">
              <Text variant="small">Line variant — active is the underline.</Text>
            </TabsContent>
            <TabsContent value="b">
              <Text variant="small">Second panel.</Text>
            </TabsContent>
          </Tabs>
        </Section>

        <Section title="Feedback">
          <View className="gap-3">
            <Progress label="Campfire XP" value={64} valueText="64/100" />
            <Progress value={100} valueText="Done" />
            <Skeleton className="h-6 w-full" />
            <Skeleton className="h-6 w-2/3" />
            <Separator />
            <Separator orientation="vertical" className="h-8 self-start" />
            <ToastButtons />
          </View>
        </Section>

        <Section title="Empty">
          <Empty>
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <Inbox size={20} strokeWidth={2.5} />
              </EmptyMedia>
              <EmptyTitle>Nothing here yet</EmptyTitle>
              <EmptyDescription>
                When a resident posts to the Nexus, it shows up here.
              </EmptyDescription>
            </EmptyHeader>
            <EmptyContent>
              <Button size="sm">Browse worlds</Button>
            </EmptyContent>
          </Empty>
        </Section>

        <Section title="Overlays">
          <View className="flex-row flex-wrap gap-3">
            <DialogDemo />
            <AlertDialogDemo />
            <SheetDemo />
            <DropdownMenuDemo />
          </View>
        </Section>
      </ScrollView>
    </ToastProvider>
  );
}

function Section({ title, children }: { title: string; children?: React.ReactNode }) {
  return (
    <View className="gap-3">
      <Text variant="section">{title}</Text>
      <View className="gap-4">{children}</View>
    </View>
  );
}

function SelectDemo() {
  const [value, setValue] = React.useState('campfire');
  return (
    <Select
      value={value}
      onValueChange={setValue}
      accessibilityLabel="World"
      options={[
        { value: 'campfire', label: 'Campfire' },
        { value: 'nexus', label: 'Nexus' },
        { value: 'identity', label: 'Identity' },
      ]}
    />
  );
}

function CheckboxDemo() {
  const [checked, setChecked] = React.useState(true);
  const [mixed, setMixed] = React.useState(false);
  return (
    <View className="flex-row items-center gap-4">
      <Checkbox checked={checked} onCheckedChange={setChecked} />
      <Checkbox checked={false} indeterminate={mixed} onCheckedChange={setMixed} />
      <Checkbox checked disabled />
    </View>
  );
}

function SwitchDemo() {
  const [on, setOn] = React.useState(true);
  return (
    <View className="flex-row items-center gap-4">
      <Switch checked={on} onCheckedChange={setOn} />
      <Switch checked={false} size="sm" onCheckedChange={() => {}} />
      <Switch checked disabled />
    </View>
  );
}

function ToastButtons() {
  const { toast } = useToast();
  return (
    <View className="flex-row flex-wrap gap-3">
      <Button variant="neutral" size="sm" onPress={() => toast({ title: 'Posted to the Nexus' })}>
        Default toast
      </Button>
      <Button
        variant="neutral"
        size="sm"
        onPress={() => toast({ title: 'Achievement unlocked', tone: 'success' })}>
        Success
      </Button>
      <Button
        variant="neutral"
        size="sm"
        onPress={() => toast({ title: 'Offline', tone: 'warning' })}>
        Warning
      </Button>
      <Button
        variant="neutral"
        size="sm"
        onPress={() => toast({ title: 'Failed', tone: 'danger' })}>
        Danger
      </Button>
    </View>
  );
}

function DialogDemo() {
  const [open, setOpen] = React.useState(false);
  return (
    <>
      <Button size="sm" onPress={() => setOpen(true)}>
        Dialog
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Leave this world?</DialogTitle>
            <DialogDescription>Your residents will notice.</DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button size="sm" variant="neutral" onPress={() => setOpen(false)}>
              Stay
            </Button>
            <Button size="sm" onPress={() => setOpen(false)}>
              Leave
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}

function AlertDialogDemo() {
  const [open, setOpen] = React.useState(false);
  return (
    <>
      <Button size="sm" variant="neutral" onPress={() => setOpen(true)}>
        Alert dialog
      </Button>
      <AlertDialog open={open} onOpenChange={setOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete message?</AlertDialogTitle>
            <AlertDialogDescription>This cannot be undone.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onPress={() => setOpen(false)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onPress={() => setOpen(false)}>Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

function SheetDemo() {
  const [open, setOpen] = React.useState(false);
  return (
    <>
      <Button size="sm" variant="neutral" onPress={() => setOpen(true)}>
        Sheet
      </Button>
      <Sheet open={open} onOpenChange={setOpen} side="bottom">
        <SheetContent>
          <SheetHeader>
            <SheetTitle>Switch world</SheetTitle>
            <SheetDescription>Pick where you are posting from.</SheetDescription>
          </SheetHeader>
          <View className="gap-2">
            <Button variant="neutral" onPress={() => setOpen(false)}>
              Campfire
            </Button>
            <Button variant="neutral" onPress={() => setOpen(false)}>
              Nexus
            </Button>
          </View>
        </SheetContent>
      </Sheet>
    </>
  );
}

function DropdownMenuDemo() {
  const [pressed, setPressed] = React.useState(0);
  return (
    <DropdownMenu
      title="Post actions"
      items={[
        { value: 'bookmark', label: 'Bookmark', onPress: () => setPressed((n) => n + 1) },
        { value: 'mute', label: 'Mute resident', onPress: () => setPressed((n) => n + 1) },
        {
          value: 'report',
          label: 'Report',
          destructive: true,
          onPress: () => setPressed((n) => n + 1),
        },
      ]}
      trigger={
        <Button size="sm" variant="neutral">
          Menu {pressed > 0 ? `(${pressed})` : ''}
        </Button>
      }
    />
  );
}
